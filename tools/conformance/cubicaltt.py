#!/usr/bin/env python3
"""Run cubicaltt (a cubical type theory proof checker) under Yale Haskell.

    tools/conformance/cubicaltt.py [-v] [-j N] [--timeout S] [NAME ...]

cubicaltt (https://github.com/mortberg/cubicaltt, MIT licence) is about
3,000 lines of GHC Haskell plus a BNFC/Alex/Happy parser: GHC extensions,
mtl, containers, pretty, QuickCheck, haskeline, time, GetOpt.  The
sources are fetched into ref/cubicaltt at a pinned commit; the generated
parser (Exp/, made with BNFC 2.9.6, Alex and Happy 2.0) and stub C
headers are kept in tools/conformance/cubicaltt/.  Each examples/NAME.ctt
is checked with `cubical -b NAME.ctt` from inside examples/ and its
standard output compared with GHC 9.14's (tools/conformance/cubicaltt/
expected/; cubicaltt writes nothing to standard error, where Yale's
compile-time diagnostics go).
lambek.ctt is left out: it fails under GHC too and then loops on its
input prompt.  Prints pass / FAIL per example with Yale's time and GHC's.
"""

import argparse
import concurrent.futures
import os
import shutil
import subprocess
import sys
import tarfile
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HERE = os.path.join(ROOT, 'tools', 'conformance', 'cubicaltt')
REF = os.path.join(ROOT, 'ref', 'cubicaltt')
WORK = os.path.join(ROOT, 'build', 'conformance', 'cubicaltt')
YALE = os.path.join(ROOT, 'bin', 'yale-haskell')
SHA = '9baa6f2491cc61dbd4fd81d58323c04100381451'
URL = 'https://github.com/mortberg/cubicaltt/archive/%s.tar.gz' % SHA
SKIP = {'lambek'}


def fetch():
    if os.path.isdir(REF):
        return
    print('fetching cubicaltt %s into ref/cubicaltt' % SHA[:12])
    os.makedirs(os.path.dirname(REF), exist_ok=True)
    tmp = REF + '.tar.gz'
    urllib.request.urlretrieve(URL, tmp)
    with tarfile.open(tmp) as t:
        t.extractall(os.path.dirname(REF), filter='data')
    os.rename(os.path.join(os.path.dirname(REF), 'cubicaltt-' + SHA), REF)
    os.remove(tmp)


def setup():
    """The work directory: the sources, the generated parser, the examples."""
    os.makedirs(WORK, exist_ok=True)
    for f in os.listdir(REF):
        if f.endswith('.hs') and f != 'Setup.hs':
            shutil.copy(os.path.join(REF, f), WORK)
    shutil.copytree(os.path.join(HERE, 'Exp'), os.path.join(WORK, 'Exp'),
                    dirs_exist_ok=True)
    shutil.copytree(os.path.join(REF, 'examples'), os.path.join(WORK, 'examples'),
                    dirs_exist_ok=True)


def command(args):
    return [YALE, '--haskell98', '--modern-prelude', '--cpp',
            '-I', os.path.join(HERE, 'include'), '-D__GLASGOW_HASKELL__=914',
            os.path.join(WORK, 'Main.hs')] + args


def run(name, timeout):
    start = time.time()
    try:
        p = subprocess.run(command(['-b', name + '.ctt']),
                           cwd=os.path.join(WORK, 'examples'),
                           stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                           stderr=subprocess.DEVNULL, timeout=timeout)
        out = p.stdout.decode('utf-8', 'replace')
    except subprocess.TimeoutExpired:
        return name, None, time.time() - start
    return name, out, time.time() - start


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-v', action='store_true', help='show a failure\'s first differing lines')
    ap.add_argument('-j', type=int, default=1, help='examples run at once')
    ap.add_argument('--timeout', type=float, default=1800)
    ap.add_argument('names', nargs='*')
    a = ap.parse_args()
    fetch()
    setup()
    ghc = {}
    with open(os.path.join(HERE, 'expected', 'ghc-times.txt')) as f:
        for line in f:
            n, t = line.split()
            ghc[n] = float(t)
    names = a.names or sorted(f[:-4] for f in os.listdir(os.path.join(WORK, 'examples'))
                              if f.endswith('.ctt') and f[:-4] not in SKIP)
    # one run first, so that the others find the compiled units cached
    first = [run(names[0], a.timeout)]
    with concurrent.futures.ThreadPoolExecutor(max(1, a.j)) as ex:
        results = first + list(ex.map(lambda n: run(n, a.timeout), names[1:]))
    passed = 0
    total_yale = total_ghc = 0.0
    for name, out, secs in results:
        with open(os.path.join(HERE, 'expected', name + '.out')) as f:
            want = f.read()
        g = ghc.get(name, 0.0)
        if out is None:
            status = 'TIMEOUT'
        elif out == want:
            status = 'pass'
            passed += 1
            total_yale += secs
            total_ghc += g
        else:
            status = 'FAIL'
        print('%-8s %-14s %8.2fs  (GHC %.2fs)' % (status, name, secs, g))
        if status == 'FAIL' and a.v and out is not None:
            got, exp = out.splitlines(), want.splitlines()
            for i in range(max(len(got), len(exp))):
                gl = got[i] if i < len(got) else '<end>'
                el = exp[i] if i < len(exp) else '<end>'
                if gl != el:
                    print('    line %d: got %r\n            want %r' % (i + 1, gl[:100], el[:100]))
                    break
    print('%d of %d pass; passing examples took %.1fs (GHC %.1fs)'
          % (passed, len(results), total_yale, total_ghc))
    sys.exit(0 if passed == len(results) else 1)


if __name__ == '__main__':
    main()
