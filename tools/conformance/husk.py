#!/usr/bin/env python3
"""Run husk-scheme, an R7RS Scheme written in Haskell, under Yale Haskell.

    tools/conformance/husk.py [-v]

husk-scheme 3.20 (MIT licence; about 11,000 lines: parsec, mtl's ExceptT,
existential types, IORef environments, hygienic macros, call/cc) is
fetched into ref/ and its interpreter, huski, runs unchanged as

    yale-haskell --haskell98 --modern-prelude --cpp -DUseLibraries
                 -DUsePointers shell.hs

with Cabal's default flags.  Only Paths_husk_scheme, which Cabal generates,
is supplied (tools/conformance/husk/Paths_husk_scheme.hs).  husk's own
test suites (tests/run-tests.scm: about 900 assertions over R5RS and R7RS
procedures, macros, continuations and SRFIs; run-tests7.scm, R7RS
libraries; r5rs_pitfall.scm) are run and compared with GHC 9.14's huski
on the same sources (tools/conformance/husk/*.out).  GHC's run fails one
numerical assertion (a floating-point 2.9999999999999996); Yale's fails
the same one.  For GHC, mtl 2.3 needs husk's modules to import
Control.Monad and liftIO themselves, an import-only change in GHC's copy.
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
HERE = os.path.join(ROOT, 'tools', 'conformance', 'husk')
REF = os.path.join(ROOT, 'ref', 'husk-scheme')
WORK = os.path.join(ROOT, 'build', 'conformance', 'husk')
YALE = os.path.join(ROOT, 'bin', 'yale-haskell')
URL = 'https://github.com/justinethier/husk-scheme/archive/refs/tags/v3.20.tar.gz'
SHA256 = 'ceb2bd09fa4276e60d78017c6b4c5091acc963a23b8087b52faaf6974000f0d0'
SUITES = ['run-tests', 'run-tests7', 'r5rs_pitfall']


def fetch():
    if os.path.isdir(REF):
        return
    tmp = REF + '.tar.gz'
    urllib.request.urlretrieve(URL, tmp)
    with open(tmp, 'rb') as f:
        if hashlib.sha256(f.read()).hexdigest() != SHA256:
            sys.exit('husk-scheme v3.20 is not the version expected')
    with tarfile.open(tmp) as t:
        t.extractall(os.path.dirname(REF), filter='data')
    os.rename(os.path.join(os.path.dirname(REF), 'husk-scheme-3.20'), REF)
    os.remove(tmp)


def setup():
    if os.path.isdir(WORK):
        shutil.rmtree(WORK)
    os.makedirs(WORK)
    shutil.copytree(os.path.join(REF, 'hs-src', 'Language'), os.path.join(WORK, 'Language'))
    shutil.copy(os.path.join(REF, 'hs-src', 'Interpreter', 'shell.hs'), WORK)
    shutil.copytree(os.path.join(REF, 'lib'), os.path.join(WORK, 'lib'))
    shutil.copytree(os.path.join(REF, 'tests'), os.path.join(WORK, 'tests'))
    shutil.copy(os.path.join(HERE, 'Paths_husk_scheme.hs'), WORK)


def huski():
    return [YALE, '--haskell98', '--modern-prelude', '--cpp', '-DUseLibraries',
            '-DUsePointers', os.path.join(WORK, 'shell.hs')]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-v', action='store_true')
    a = ap.parse_args()
    fetch()
    setup()
    env = dict(os.environ, husk_scheme_datadir=WORK)
    start = time.time()
    p = subprocess.run(huski() + ['--help'], env=env, stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT)
    if p.returncode != 0:
        print(p.stdout.decode('utf-8', 'replace')[-3000:])
        sys.exit('huski did not compile')
    print('huski compiled (%.0fs)' % (time.time() - start))
    failed = False
    for suite in SUITES:
        start = time.time()
        p = subprocess.run(huski() + [suite + '.scm'], cwd=os.path.join(WORK, 'tests'),
                           env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        out = p.stdout.decode('utf-8', 'replace')
        want = open(os.path.join(HERE, suite + '.out')).read()
        same = out == want
        failed |= not same
        print('%-14s %s (%.1fs)' % (suite, 'matches GHC' if same else 'DIFFERS from GHC',
                                    time.time() - start))
        if not same and a.v:
            import difflib
            sys.stdout.writelines(difflib.unified_diff(want.splitlines(True),
                                                       out.splitlines(True), 'ghc', 'yale'))
    if failed:
        sys.exit(1)


if __name__ == '__main__':
    main()
