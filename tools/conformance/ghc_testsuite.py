#!/usr/bin/env python3
"""Run GHC's own testsuite programs (its compile_and_run tests) with Yale Haskell.

    tools/conformance/ghc_testsuite.py [-t SECONDS] [-v] [--list] [DIR ...]

The testsuite is GHC 9.14.1's (ref/ghc-testsuite, a sparse clone of
https://gitlab.haskell.org/ghc/ghc at ghc-9.14.1-release, 902339d; see
ref/README.md).  DIR is a directory under testsuite/tests (default:
DEFAULT_DIRS).  Each all.T there is read without running it: its top-level
test(NAME, SETUP, compile_and_run, [FLAGS]) calls, of which a single-module
test whose setup GHC does not skip on this machine is run as

    yale-haskell --ghc2021 [-X ..] run NAME.hs [extra_run_opts] < NAME.stdin

in its own directory under build/conformance/ghc-testsuite/, with the test
directory on the module search path and its extra_files copied there, and
a time limit (tools/bound).  Its stdout (whitespace normalised, as the
testsuite driver does) and exit code are compared with NAME.stdout and
exit_code(N); stderr is compared separately, since runtime errors are
worded differently.

A result is PASS, WRONG (output differs), EXIT (exit code differs),
COMPILE (a compile error), RUNTIME (an error at run time with wrong
output), TIMEOUT or SKIP (why: expect_broken in GHC itself, C sources,
GHC's internals, ways Yale has not).  results.tsv, report.txt (per
directory, and compile errors grouped by kind) are written to the output
directory.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TESTS = os.path.join(ROOT, 'ref', 'ghc-testsuite', 'testsuite', 'tests')
OUT = os.path.join(ROOT, 'build', 'conformance', 'ghc-testsuite')
YALE = os.path.join(ROOT, 'bin', 'yale-haskell')
BOUND = os.path.join(ROOT, 'tools', 'bound')

# The language-level directories; perf, profiling, rts, ghci, ghc-api,
# driver, javascript, simd and the like test GHC itself.
DEFAULT_DIRS = [
    'typecheck/should_run', 'deriving/should_run', 'deSugar/should_run',
    'codeGen/should_run', 'numeric/should_run', 'parser/should_run',
    'array/should_run', 'simplCore/should_run', 'dmdanal/should_run',
    'concurrent/should_run', 'overloadedrecflds/should_run', 'default',
    'process', 'mdo/should_run', 'arrows/should_run', 'gadt',
    'indexed-types/should_run', 'polykinds', 'quantified-constraints',
    'patsyn/should_run', 'rebindable', 'programs', 'ado',
    'overloadedlists/should_run', 'overloadedstrings/should_run',
    'records/should_run', 'th', 'ffi/should_run', 'unboxedsums',
    'primops/should_run',
]

# Conditions of when(COND, skip) as they are on this machine.
TRUE_PREDS = {"opsys('darwin')", "arch('aarch64')", "wordsize(64)", "platform('aarch64-apple-darwin')"}


def split_top(s, sep=','):
    """Split S at SEP outside brackets and strings."""
    parts, depth, cur, quote = [], 0, [], None
    i = 0
    while i < len(s):
        c = s[i]
        if quote:
            cur.append(c)
            if c == '\\' and i + 1 < len(s):
                cur.append(s[i + 1]); i += 1
            elif c == quote:
                quote = None
        elif c in '\'"':
            quote = c; cur.append(c)
        elif c in '([{':
            depth += 1; cur.append(c)
        elif c in ')]}':
            depth -= 1; cur.append(c)
        elif c == sep and depth == 0:
            parts.append(''.join(cur).strip()); cur = []
        else:
            cur.append(c)
        i += 1
    if ''.join(cur).strip():
        parts.append(''.join(cur).strip())
    return parts


def strip_comments(text):
    out = []
    for line in text.split('\n'):
        q, res = None, []
        for c in line:
            if q:
                res.append(c)
                if c == q:
                    q = None
            elif c in '\'"':
                q = c; res.append(c)
            elif c == '#':
                break
            else:
                res.append(c)
        out.append(''.join(res))
    return '\n'.join(out)


def test_calls(text):
    """The top-level test(...) calls: lists of their arguments."""
    text = strip_comments(text)
    calls = []
    for m in re.finditer(r'(?m)^test\s*\(', text):
        i = m.end(); depth = 1; q = None
        while i < len(text) and depth:
            c = text[i]
            if q:
                if c == '\\':
                    i += 1
                elif c == q:
                    q = None
            elif c in '\'"':
                q = c
            elif c in '([{':
                depth += 1
            elif c in ')]}':
                depth -= 1
            i += 1
        calls.append(split_top(text[m.end():i - 1]))
    return calls


def unquote(s):
    s = s.strip()
    if len(s) >= 2 and s[0] in '\'"' and s[-1] == s[0]:
        return s[1:-1]
    return None


def string_args(s):
    """The string literals in S, joined (a flags list ['-O', '-XFoo'])."""
    return ' '.join(a or b for a, b in re.findall(r"'([^']*)'|\"([^\"]*)\"", s))


def condition_true(cond):
    """A when(...) condition, from predicates known on this machine; True
    when it cannot be decided (the test is then skipped)."""
    expr = cond
    for p in re.findall(r"[a-z_]+\([^()]*\)", cond):
        val = p.replace('"', "'") in TRUE_PREDS
        if p.startswith('fast(') or p.startswith('unregisterised(') or p.startswith('js_arch(') \
           or p.startswith('wasm_arch(') or p.startswith('ghc_dynamic(') or p.startswith('have_profiling(') \
           or p.startswith('compiler_debugged(') or p.startswith('debug_rts(') or p.startswith('ghc_with_threaded_rts('):
            val = p.startswith('ghc_with_threaded_rts(')
        elif not (p.startswith('opsys(') or p.startswith('arch(') or p.startswith('wordsize(')
                  or p.startswith('platform(')):
            return True
        expr = expr.replace(p, 'True' if val else 'False')
    if not re.fullmatch(r"[\sA-Za-z()]*", expr) or set(re.findall(r'[A-Za-z]+', expr)) - {'True', 'False', 'not', 'and', 'or'}:
        return True
    return eval(expr, {'__builtins__': {}}, {})


def setup_options(setup):
    """(skip-reason or None, extra_files, run_opts, exit_code, ignore_stdout)."""
    items = split_top(setup[1:-1]) if setup.startswith('[') else [setup]
    files, run_opts, code, ignore_out, skip = [], '', 0, False, None
    for it in items:
        if it in ('skip',):
            skip = 'skip'
        m = re.match(r'when\s*\((.*),\s*(skip|expect_broken\(\d+\))\s*\)$', it, re.S)
        if m and condition_true(m.group(1)):
            skip = 'when(%s)' % m.group(1)
        if it.startswith('expect_broken(') or it.startswith('expect_broken_for(') and 'normal' in it:
            skip = 'GHC: ' + it
        if re.match(r'(only_ways|only_compiler_types)\s*\(', it) and not re.search(r"'normal'|ghc", it):
            skip = it
        if it.startswith(('req_profiling', 'req_interp', 'req_rts_linker', 'req_dynamic', 'req_cmm')):
            skip = it
        m = re.match(r'extra_files\s*\((.*)\)$', it, re.S)
        if m:
            files += [a or b for a, b in re.findall(r"'([^']*)'|\"([^\"]*)\"", m.group(1))]
        m = re.match(r'extra_run_opts\s*\((.*)\)$', it, re.S)
        if m:
            run_opts = unquote(m.group(1)) or ''
        m = re.match(r'exit_code\s*\(\s*(\d+)\s*\)$', it)
        if m:
            code = int(m.group(1))
        if it == 'ignore_stdout':
            ignore_out = True
    return skip, files, run_opts, code, ignore_out


def select(dirname):
    """[(name, source, skip-reason, flags, files, run_opts, exit_code, ignore_out)]."""
    path = os.path.join(TESTS, dirname)
    allt = os.path.join(path, 'all.T')
    if not os.path.exists(allt):
        return []
    tests = []
    for args in test_calls(open(allt, errors='replace').read()):
        if len(args) < 4 or args[2].strip() != 'compile_and_run':
            continue
        name = unquote(args[0])
        if not name:
            continue
        src = None
        for ext in ('.hs', '.lhs'):
            if os.path.exists(os.path.join(path, name + ext)):
                src = name + ext
        skip, files, run_opts, code, ignore_out = setup_options(args[1].strip())
        flags = string_args(args[3])
        if src is None:
            skip = skip or 'no %s.hs' % name
        if re.search(r'\.(c|cpp|cmm|s|S)\b', flags) or re.search(r'-package\s+ghc\b|-package\s+ghc-internal', flags):
            skip = skip or 'C sources or GHC internals: ' + flags
        tests.append((name, src, skip, flags, files, run_opts, code, ignore_out))
    return tests


def yale_flags(flags):
    """The -X and -D flags of a GHC command line, as Yale's."""
    out = []
    for f in flags.split():
        if f.startswith('-X'):
            out.append(f)
        elif f.startswith('-D') or f == '-cpp':
            out.append('--cpp' if f == '-cpp' else f)
    return out


def normalise(s):
    return '\n'.join(' '.join(l.split()) for l in s.replace('\r', '').split('\n')).strip()


COMPILE_ERR = re.compile(r'^\[([A-Z0-9-]+)\] (?:Phase|Fatal) error in phase (\w[\w-]*):\n(.*)$', re.M)


def run_test(dirname, t, seconds, verbose):
    name, src, skip, flags, files, run_opts, code, ignore_out = t
    if skip:
        return 'SKIP', skip, ''
    path = os.path.join(TESTS, dirname)
    work = os.path.join(OUT, 'work', dirname.replace('/', '_'), name)
    if os.path.exists(work):
        shutil.rmtree(work)
    os.makedirs(work)
    for f in files:
        p = os.path.join(path, f)
        if os.path.isdir(p):
            shutil.copytree(p, os.path.join(work, os.path.basename(f.rstrip('/'))))
        elif os.path.exists(p):
            shutil.copy(p, work)
    stdin_file = os.path.join(path, name + '.stdin')
    stdin = open(stdin_file, 'rb') if os.path.exists(stdin_file) else subprocess.DEVNULL
    cmd = [BOUND, str(seconds), YALE, '--ghc2021', '-i', path] + yale_flags(flags) + \
          ['run', os.path.join(path, src)] + run_opts.split()
    t0 = time.time()
    p = subprocess.run(cmd, cwd=work, stdin=stdin, capture_output=True)
    dt = time.time() - t0
    out = p.stdout.decode('utf-8', 'replace')
    err = p.stderr.decode('utf-8', 'replace')
    expected = ''
    for suffix in ('.stdout-ws-64', '.stdout'):
        e = os.path.join(path, name + suffix)
        if os.path.exists(e):
            expected = open(e, errors='replace').read()
            break
    m = COMPILE_ERR.search(err)
    if p.returncode == 124:
        res, why = 'TIMEOUT', '%.0f s' % dt
    elif m and normalise(out) == '' and p.returncode != 0:
        res, why = 'COMPILE', '[%s] %s: %s' % (m.group(1), m.group(2), m.group(3).strip()[:160])
    elif not ignore_out and normalise(out) != normalise(expected):
        res = 'RUNTIME' if p.returncode != code and p.returncode != 0 else 'WRONG'
        why = (err.strip().split('\n')[-1] if res == 'RUNTIME' else 'stdout differs')[:160]
    elif p.returncode != code:
        res, why = 'EXIT', 'exit %d, expected %d: %s' % (p.returncode, code, err.strip()[-120:])
    else:
        res, why = 'PASS', '%.1f s' % dt
    with open(os.path.join(work, 'yale.stdout'), 'w') as f:
        f.write(out)
    with open(os.path.join(work, 'yale.stderr'), 'w') as f:
        f.write(err)
    if verbose:
        print('%-8s %s/%s %s' % (res, dirname, name, why), flush=True)
    return res, why, err


def bucket(why):
    """A compile error's kind: its id and phase, and its message with the
    names and numbers in it elided."""
    m = re.match(r'(\[[A-Z0-9-]+\] [\w-]+: )(.*)$', why, re.S)
    head, msg = (m.group(1), m.group(2)) if m else ('', why)
    msg = re.sub(r'(?<=file )\S+', '_', msg)
    msg = re.sub(r"`[^`']*'|\b[A-Z][\w.']*|\b\d+\b|[^\w\s(),.:;]+", '_', msg)
    return (head + msg)[:120]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('-t', type=int, default=60, help='seconds per test (default 60)')
    ap.add_argument('-v', action='store_true')
    ap.add_argument('--list', action='store_true', help='only count the tests selected')
    ap.add_argument('dirs', nargs='*')
    a = ap.parse_args()
    if not os.path.isdir(TESTS):
        sys.exit('no %s: see ref/README.md' % TESTS)
    dirs = a.dirs or list(dict.fromkeys(DEFAULT_DIRS))
    os.makedirs(OUT, exist_ok=True)
    results = []
    for d in dirs:
        tests = select(d)
        if a.list:
            print('%5d run, %4d skip  %s' % (sum(1 for t in tests if not t[2]),
                                            sum(1 for t in tests if t[2]), d))
            continue
        for t in tests:
            res, why, _ = run_test(d, t, a.t, a.v)
            results.append((d, t[0], res, why))
    if a.list:
        return
    with open(os.path.join(OUT, 'results.tsv'), 'w') as f:
        for r in results:
            f.write('\t'.join(r) + '\n')
    kinds = ['PASS', 'WRONG', 'EXIT', 'RUNTIME', 'COMPILE', 'TIMEOUT', 'SKIP']
    lines = []
    tot = {k: 0 for k in kinds}
    for d in dirs:
        c = {k: 0 for k in kinds}
        for r in results:
            if r[0] == d:
                c[r[2]] += 1
        for k in kinds:
            tot[k] += c[k]
        lines.append('%-32s ' % d + ' '.join('%s %d' % (k, c[k]) for k in kinds if c[k]))
    ran = sum(tot[k] for k in kinds if k != 'SKIP')
    lines.insert(0, 'total: %d run, %d pass (%.0f%%); ' % (ran, tot['PASS'], 100.0 * tot['PASS'] / max(ran, 1))
                 + ' '.join('%s %d' % (k, tot[k]) for k in kinds) + '\n')
    groups = {}
    for r in results:
        if r[2] == 'COMPILE':
            groups.setdefault(bucket(r[3]), []).append('%s/%s' % (r[0], r[1]))
    lines.append('\ncompile errors by kind:')
    for k, v in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        lines.append('%4d  %s\n      %s' % (len(v), k, ' '.join(v[:6])))
    report = '\n'.join(lines) + '\n'
    with open(os.path.join(OUT, 'report.txt'), 'w') as f:
        f.write(report)
    print(report)


if __name__ == '__main__':
    main()
