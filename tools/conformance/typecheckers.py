#!/usr/bin/env python3
"""Run two small dependently typed checkers under Yale Haskell.

    tools/conformance/typecheckers.py [-v] [NAME ...]

NAME is one of lambdapi-smoke, lambdapi-bench, minitt-paper, minitt-bench
(default: all).  LambdaPi runs in Yale's Haskell 98 mode, as written;
Mini-TT with --modern-prelude, like cubicaltt (CUBICALTT.md).  The
sources are fetched into ref/ at pinned versions (see
tools/conformance/typecheckers/README.md); Mini-TT's parser is generated
with bnfc, alex and happy, which must be on PATH (or in $BNFC_BIN).
Each run's standard output is compared with GHC 9.14's; prints pass /
FAIL with Yale's time and GHC's.
"""

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tarfile
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HERE = os.path.join(ROOT, 'tools', 'conformance', 'typecheckers')
WORK = os.path.join(ROOT, 'build', 'conformance')
YALE = os.path.join(ROOT, 'bin', 'yale-haskell')

LP_URL = 'https://www.andres-loeh.de/LambdaPi/'
LP_FILES = {
    'LambdaPi.hs': 'df589b67607c55b99da96a1cc74a38b9c5d9e5ca1f1f2f6237536b00d6f10826',
    'prelude.lp': '34800bf1b9f3c53aa001261424d6175a605ee1d85a2ed5df5d8367c05cf42030',
}
MTT_SHA = '442b08f9a56c25ff79bc8c007c78be6197daed61'
MTT_URL = 'https://github.com/kino3/Mini-TT/archive/%s.tar.gz' % MTT_SHA
PAPER_URL = ('https://raw.githubusercontent.com/scott-fleischman/mini-tt/'
             '64b615ae00326dfad9f19ff71e4b341c66cf747d/examples/paper.mtt')

ALL = ['lambdapi-smoke', 'lambdapi-bench', 'minitt-paper', 'minitt-bench']


def fetch_lambdapi():
    ref = os.path.join(ROOT, 'ref', 'lambdapi')
    os.makedirs(ref, exist_ok=True)
    for name, digest in LP_FILES.items():
        path = os.path.join(ref, name)
        if not os.path.exists(path):
            urllib.request.urlretrieve(LP_URL + name, path)
        with open(path, 'rb') as f:
            if hashlib.sha256(f.read()).hexdigest() != digest:
                sys.exit('ref/lambdapi/%s is not the version expected' % name)
    work = os.path.join(WORK, 'lambdapi')
    os.makedirs(work, exist_ok=True)
    shutil.copy(os.path.join(ref, 'LambdaPi.hs'), os.path.join(work, 'LP.hs'))
    shutil.copy(os.path.join(ref, 'prelude.lp'), work)
    for f in os.listdir(os.path.join(HERE, 'lambdapi')):
        shutil.copy(os.path.join(HERE, 'lambdapi', f), work)
    return work


def fetch_minitt():
    ref = os.path.join(ROOT, 'ref', 'Mini-TT')
    if not os.path.isdir(ref):
        tmp = ref + '.tar.gz'
        urllib.request.urlretrieve(MTT_URL, tmp)
        with tarfile.open(tmp) as t:
            t.extractall(os.path.dirname(ref), filter='data')
        os.rename(os.path.join(os.path.dirname(ref), 'Mini-TT-' + MTT_SHA), ref)
        os.remove(tmp)
    paper = os.path.join(ref, 'paper.mtt')
    if not os.path.exists(paper):
        urllib.request.urlretrieve(PAPER_URL, paper)
    work = os.path.join(WORK, 'minitt')
    os.makedirs(work, exist_ok=True)
    for f in ('Main.hs', 'Core.cf', 'paper.mtt'):
        shutil.copy(os.path.join(ref, f), work)
    shutil.copy(os.path.join(HERE, 'minitt', 'bench.mtt'), work)
    if not os.path.exists(os.path.join(work, 'Core', 'Par.hs')):
        env = dict(os.environ)
        if os.environ.get('BNFC_BIN'):
            env['PATH'] = os.environ['BNFC_BIN'] + os.pathsep + env['PATH']
        for cmd in (['bnfc', '--haskell', '-d', 'Core.cf'],
                    ['alex', 'Core/Lex.x'], ['happy', 'Core/Par.y']):
            if shutil.which(cmd[0], path=env['PATH']) is None:
                print('SKIP Mini-TT: %s is not on PATH (set BNFC_BIN)' % cmd[0])
                return None
            subprocess.run(cmd, cwd=work, env=env, check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return work


def run(name, work, timeout):
    prog, case = name.split('-', 1)
    if prog == 'lambdapi':
        cmd = [YALE, '--haskell98', 'Main.hs']
        stdin = open(os.path.join(work, case + '.in'), 'rb')
    else:
        cmd = [YALE, '--haskell98', '--modern-prelude', '--cpp',
               '-I', os.path.join(ROOT, 'tools', 'conformance', 'cubicaltt', 'include'),
               '-D__GLASGOW_HASKELL__=914', 'Main.hs', case + '.mtt']
        stdin = subprocess.DEVNULL
    start = time.time()
    try:
        p = subprocess.run(cmd, cwd=work, stdin=stdin, stdout=subprocess.PIPE,
                           stderr=subprocess.DEVNULL, timeout=timeout)
        out = p.stdout.decode('utf-8', 'replace')
    except subprocess.TimeoutExpired:
        out = None
    return out, time.time() - start


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-v', action='store_true')
    ap.add_argument('--timeout', type=float, default=600)
    ap.add_argument('names', nargs='*')
    a = ap.parse_args()
    names = a.names or ALL
    ghc = {}
    with open(os.path.join(HERE, 'expected', 'ghc-times.txt')) as f:
        for line in f:
            n, t = line.split()
            ghc[n] = float(t)
    works = {}
    if any(n.startswith('lambdapi') for n in names):
        works['lambdapi'] = fetch_lambdapi()
    if any(n.startswith('minitt') for n in names):
        works['minitt'] = fetch_minitt()
    passed = total = 0
    for name in names:
        work = works[name.split('-')[0]]
        if work is None:
            continue
        total += 1
        # the first run of each program compiles it; time the second
        run(name, work, a.timeout)
        out, secs = run(name, work, a.timeout)
        with open(os.path.join(HERE, 'expected', name + '.out')) as f:
            want = f.read()
        status = 'TIMEOUT' if out is None else 'pass' if out == want else 'FAIL'
        passed += status == 'pass'
        print('%-8s %-16s %7.2fs  (GHC %.2fs)' % (status, name, secs, ghc.get(name, 0)))
        if status == 'FAIL' and a.v and out is not None:
            for i, (g, w) in enumerate(zip(out.splitlines() + ['<end>'],
                                           want.splitlines() + ['<end>'])):
                if g != w:
                    print('    line %d: got %r\n            want %r' % (i + 1, g[:100], w[:100]))
                    break
    print('%d of %d pass' % (passed, total))
    sys.exit(0 if passed == total else 1)


if __name__ == '__main__':
    main()
