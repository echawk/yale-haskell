#!/usr/bin/env python3
"""Measure the typed core (src/compiler/typed/) over the test programs.

    tools/typed-core.py [-v] [FILE.hs ...]

Compiles each program (default: every tests/haskell98/**/*.hs, with its
.flags) with YALE_HASKELL_TYPED_CENSUS=1, which runs the typed phase after
cfn and reports how many expressions got a type and how many of those the
type checker also inferred and agree.  Prints the totals and the programs
where some unification failed (with -v, the failures:
YALE_HASKELL_TYPED_DEBUG=1).  Library units come from the unit cache and
are not retyped; YALE_HASKELL_CACHE=0 in the environment retypes them too.
"""
import argparse, glob, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
YALE = os.path.join(ROOT, 'bin', 'yale-haskell')
REPORT = re.compile(r'typed core: (\d+) expressions, (\d+) typed; '
                    r'(\d+) with an inferred type, (\d+) agree')
FAIL = re.compile(r'^(APP|BINDING|SEL|IS-CONSTRUCTOR|IF-TEST|IF-BRANCHES|'
                  r'RETURN-FROM|AND): ', re.M)


def flags_for(path):
    f = path[:-3] + '.flags'
    return open(f).read().split() if os.path.exists(f) else []


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-v', action='store_true')
    ap.add_argument('files', nargs='*')
    args = ap.parse_args()
    files = args.files or sorted(glob.glob(os.path.join(ROOT, 'tests', 'haskell98',
                                                        '**', '*.hs'), recursive=True))
    env = dict(os.environ, YALE_HASKELL_TYPED_CENSUS='1', YALE_HASKELL_TYPED_DEBUG='1')
    totals = [0, 0, 0, 0]
    failing = []
    for f in files:
        r = subprocess.run([YALE, '--haskell98'] + flags_for(f) + ['compile', f],
                           capture_output=True, text=True, env=env)
        for m in REPORT.finditer(r.stderr):
            for i in range(4):
                totals[i] += int(m.group(i + 1))
        n = len(FAIL.findall(r.stderr))
        if n:
            failing.append((n, os.path.relpath(f, ROOT), r.stderr))
    e, t, c, a = totals
    print('%d expressions, %d typed (%.2f%%); %d with an inferred type, %d agree (%.2f%%)'
          % (e, t, 100.0 * t / max(e, 1), c, a, 100.0 * a / max(c, 1)))
    for n, f, err in sorted(failing, reverse=True):
        print('  %4d unification failures  %s' % (n, f))
        if args.v:
            for line in err.splitlines():
                if FAIL.match(line) or line.startswith('  in '):
                    print('        ' + line[:200])
    return 0


if __name__ == '__main__':
    sys.exit(main())
