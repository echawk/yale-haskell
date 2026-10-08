#!/usr/bin/env python3
"""Run nofib programs (ref/nofib, see ref/README.md) with Yale Haskell 98.

    tools/conformance/nofib.py [-t SECONDS] [-v] [PROGRAM_DIR ...]

Default: every program under ref/nofib/imaginary and ref/nofib/spectral.
Each program is copied to build/conformance/<suite>/<name>/, its
hierarchical imports are mapped to Haskell 98 module names
(Data.List -> List, ...), and it is run with its FAST_OPTS and stdin
against <name>.faststdout (else <name>.stdout).  The result of each
program is one of: pass, WRONG (output differs), COMPILE (compile
error), RUNTIME (runtime error), TIMEOUT, SKIP (uses something Haskell
98 lacks), KNOWN (a recorded deviation, see KNOWN).  A summary and a report file build/conformance/report.txt
are written.
"""
import os, re, shutil, subprocess, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NOFIB = os.path.join(ROOT, 'ref', 'nofib')
OUT = os.path.join(ROOT, 'build', 'conformance')

MODULE_MAP = {
    'Data.List': 'List', 'Data.Char': 'Char', 'Data.Maybe': 'Maybe',
    'Data.Array': 'Array', 'Data.Ix': 'Ix', 'Data.Ratio': 'Ratio',
    'Data.Complex': 'Complex', 'Control.Monad': 'NofibMonad',
    'System.Environment': 'System', 'System.Exit': 'System',
    'System.IO': 'IO', 'System.CPUTime': 'CPUTime', 'System.Random': 'Random',
    'System.Directory': 'Directory', 'System.Time': 'Time', 'System.Locale': 'Locale',
    'Numeric': 'Numeric', 'Prelude': 'Prelude',
}
# Modules with no Haskell 98 counterpart: the program is skipped.
NON_H98 = re.compile(r'^>?\s*import\s+(qualified\s+)?(Data\.(Bits|IORef|Word|Int|Map|Set|IntMap|STRef|Array\.\w+)|Control\.(Monad\.\w+|Exception|Concurrent|Parallel|DeepSeq)|GHC\.|Foreign|Text\.|System\.(Mem|Process|Info)|Debug)', re.M)
EXTENSIONS = re.compile(r'\{-#\s*LANGUAGE|\bforall\b|\bunsafePerformIO\b|#!|^\s*#\s*(if|include|define)', re.M)

# Programs that cannot pass for a known reason outside Haskell 98
# conformance: reported as KNOWN with the reason.
KNOWN = {
    'spectral/sphere': 'its hash relies on 64-bit Int wrap-around (H98 leaves overflow undefined; Int is the 62-bit fixnum range)',
    'spectral/mandel': 'uses hSetBinaryMode (not Haskell 98)',
    'spectral/mandel2': 'uses <$> (not in the Haskell 98 Prelude)',
    'spectral/life': 'uses <$> (not in the Haskell 98 Prelude)',
    'spectral/simple': 'uses <$> (not in the Haskell 98 Prelude)',
}

def read(p):
    with open(p, encoding='latin-1') as f:
        return f.read()

def makefile_var(mk, name):
    m = re.search(r'^\s*' + name + r'\s*[+:]?=\s*(.*)$', mk, re.M)
    return m.group(1).strip() if m else None

def map_imports(src):
    def sub(m):
        mod = m.group(3)
        return m.group(1) + (m.group(2) or '') + MODULE_MAP.get(mod, mod)
    return re.sub(r'^(>?\s*import\s+)(qualified\s+)?([A-Z][\w.]*)', sub, src, flags=re.M)

def run_program(d, timeout, verbose):
    d = d.rstrip('/')
    name = os.path.basename(d)
    suite = os.path.basename(os.path.dirname(d))
    mk = read(os.path.join(d, 'Makefile')) if os.path.exists(os.path.join(d, 'Makefile')) else ''
    srcs = [f for f in os.listdir(d) if f.endswith(('.hs', '.lhs'))]
    main = 'Main.hs' if 'Main.hs' in srcs else ('Main.lhs' if 'Main.lhs' in srcs else None)
    expected = None
    for e in (name + '.faststdout', name + '.stdout'):
        if os.path.exists(os.path.join(d, e)):
            expected = os.path.join(d, e); break
    args = (makefile_var(mk, 'FAST_OPTS') or makefile_var(mk, 'PROG_ARGS') or '').split()
    stdin_file = None
    for s_ in (name + '.faststdin', name + '.stdin'):
        if os.path.exists(os.path.join(d, s_)):
            stdin_file = os.path.join(d, s_); break
    if main is None:
        return 'SKIP', 'no Main'
    if expected is None:
        expected = ghc_expected(d, suite, name, main, args, stdin_file)
        if expected is None:
            return 'SKIP', 'no expected output, and GHC could not make one'
    work = os.path.join(OUT, suite, name)
    shutil.rmtree(work, ignore_errors=True)
    os.makedirs(work)
    shutil.copy(os.path.join(ROOT, 'tools', 'conformance', 'NofibMonad.hs'), work)
    for f in os.listdir(d):
        p = os.path.join(d, f)
        if f == 'NofibUtils.hs':
            # nofib's helper uses CPP and post-98 names: a Haskell 98 stand-in
            p = os.path.join(ROOT, 'tools', 'conformance', 'NofibUtils.hs')
            shutil.copy(p, os.path.join(work, f))
            continue
        if os.path.isdir(p):
            shutil.copytree(p, os.path.join(work, f))
            continue
        if os.path.isfile(p):
            if f.endswith(('.hs', '.lhs')):
                src = read(p)
                if NON_H98.search(src):
                    return 'SKIP', 'imports %s' % NON_H98.search(src).group(0).split()[-1]
                if EXTENSIONS.search(src):
                    return 'SKIP', 'extension: %s' % EXTENSIONS.search(src).group(0).strip()
                with open(os.path.join(work, f), 'w', encoding='latin-1') as g:
                    g.write(map_imports(src))
            else:
                shutil.copy(p, work)
    # an argument naming one of the program's files (sorting reads its own
    # Main.hs) gets the original, not the copy with its imports rewritten
    args = [os.path.join(d, a) if os.path.isfile(os.path.join(d, a)) else a for a in args]
    cmd = [os.path.join(ROOT, 'bin', 'yale-haskell'), '--haskell98', main] + args
    t0 = time.time()
    try:
        with open(stdin_file or os.devnull, 'rb') as inp:
            r = subprocess.run(cmd, cwd=work, stdin=inp, capture_output=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return 'TIMEOUT', '%ds' % timeout
    secs = time.time() - t0
    err = r.stderr.decode('latin-1')
    want = open(expected, 'rb').read()
    if r.returncode != 0:
        first = next((l for l in err.splitlines() if l.strip() and 'STYLE-WARNING' not in l), '')
        kind = 'RUNTIME' if 'runtime' in err.lower() or 'Exception' in err or 'error' in err.lower() and 'phase' not in err.lower() else 'COMPILE'
        if re.search(r'\[[A-Z-]+\] .*(error|Error) in phase', err):
            kind = 'COMPILE'
        detail = ' / '.join(l for l in err.splitlines()[:3] if l.strip())
        return kind, detail[:300]
    if r.stdout == want or r.stdout.strip() == want.strip():
        return 'pass', '%.1fs' % secs
    return 'WRONG', 'output differs (%d vs %d bytes)' % (len(r.stdout), len(want))

# nofib checks some programs only by exit status; their expected output is
# then made by GHC (the reference), from the unmodified sources, and cached.
def ghc_expected(d, suite, name, main, args, stdin_file):
    cache = os.path.join(OUT, 'ghc-expected', suite, name)
    out = os.path.join(cache, 'expected.stdout')
    if os.path.exists(out):
        return out
    ghc = shutil.which('ghc')
    if ghc is None:
        return None
    shutil.rmtree(cache, ignore_errors=True)
    shutil.copytree(d, os.path.join(cache, 'src'))
    src = os.path.join(cache, 'src')
    r = subprocess.run([ghc, '-O0', '-o', 'prog', main], cwd=src, capture_output=True)
    if r.returncode != 0:
        return None
    try:
        with open(stdin_file or os.devnull, 'rb') as inp:
            r = subprocess.run([os.path.join(src, 'prog')] + args, cwd=src, stdin=inp,
                               capture_output=True, timeout=300)
    except subprocess.TimeoutExpired:
        return None
    if r.returncode != 0:
        return None
    with open(out, 'wb') as f:
        f.write(r.stdout)
    return out

def default_programs():
    progs = []
    for suite in ('imaginary', 'spectral'):
        for p in sorted(os.listdir(os.path.join(NOFIB, suite))):
            d = os.path.join(NOFIB, suite, p)
            if not os.path.isdir(d):
                continue
            if p == 'hartel':   # a directory of programs
                progs += [os.path.join(d, q) for q in sorted(os.listdir(d))
                          if os.path.isdir(os.path.join(d, q))]
            else:
                progs.append(d)
    return progs

def main():
    argv = sys.argv[1:]
    timeout, verbose = 120, False
    while argv and argv[0].startswith('-'):
        if argv[0] == '-t': timeout = int(argv[1]); argv = argv[2:]
        elif argv[0] == '-v': verbose = True; argv = argv[1:]
        else: break
    dirs = [a for a in argv if os.path.isdir(a)] or default_programs()
    os.makedirs(OUT, exist_ok=True)
    counts, lines = {}, []
    for d in dirs:
        rel = os.path.relpath(d.rstrip('/'), NOFIB)
        if rel in KNOWN:
            res, detail = 'KNOWN', KNOWN[rel]
        else:
            res, detail = run_program(d, timeout, verbose)
        counts[res] = counts.get(res, 0) + 1
        line = '%-8s %-28s %s' % (res, os.path.relpath(d, NOFIB), detail)
        lines.append(line)
        print(line, flush=True)
    summary = ', '.join('%d %s' % (n, k) for k, n in sorted(counts.items()))
    print(summary)
    with open(os.path.join(OUT, 'report.txt'), 'w') as f:
        f.write('\n'.join(lines) + '\n' + summary + '\n')

if __name__ == '__main__':
    main()
