#!/usr/bin/env python3
"""Run optparse-applicative's test suite under Yale Haskell.

    tools/conformance/optparse.py [-v] [-k]

optparse-applicative 0.18.1.0 and the libraries it needs that Yale does
not provide, prettyprinter 1.7.1 and prettyprinter-ansi-terminal 1.1.3
(all BSD), are fetched from Hackage into ref/ and their sources copied
to build/conformance/optparse/ with the test suite (tests/test.hs, 100
QuickCheck properties, most of them help texts checked against
tests/*.err.txt).  One thing is adapted, in the build copy only:

- test.hs's main is `$(quickCheckAll)' (Template Haskell, which Yale does
  not have): it is replaced by a main that runs the prop_ functions in
  source order and prints each one's name, as quickCheckAll does.

Done when every property passes: most compare the help text optparse
renders with the golden files upstream made with GHC (tests/*.err.txt).
-v prints the compiler's output.
"""

import argparse
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tarfile
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
WORK = os.path.join(ROOT, 'build', 'conformance', 'optparse')
YALE = os.path.join(ROOT, 'bin', 'yale-haskell')

PACKAGES = [
    ('optparse-applicative-0.18.1.0',
     '63811ab4fd26e829b8868364325a88be3acc79819f5bb5005b2dd3b961ecc491'),
    ('prettyprinter-1.7.1',
     '5e6ea6903114fa118fcc359633dfb7ecddecb92c06c853d02a77b72b251f0b45'),
    ('prettyprinter-ansi-terminal-1.1.3',
     '813739308ad6050620578994effe21058a170a341716acf52573fae42b5b1db3'),
]

FLAGS = ['--haskell98', '--modern-prelude', '--cpp', '-D__GLASGOW_HASKELL__=906',
         '-I', os.path.join(ROOT, 'ref', 'prettyprinter-1.7.1', 'misc')]


def fetch():
    for name, sha in PACKAGES:
        ref = os.path.join(ROOT, 'ref', name)
        if os.path.isdir(ref):
            continue
        tmp = ref + '.tar.gz'
        urllib.request.urlretrieve(
            'https://hackage.haskell.org/package/%s/%s.tar.gz' % (name, name), tmp)
        with open(tmp, 'rb') as f:
            if hashlib.sha256(f.read()).hexdigest() != sha:
                sys.exit('%s.tar.gz is not the version expected' % name)
        with tarfile.open(tmp) as t:
            t.extractall(os.path.dirname(ref), filter='data')
        os.remove(tmp)


def adapt_test(path):
    """Replace the Template Haskell main by one listing the properties."""
    text = open(path).read()
    text = text.replace('{-# LANGUAGE TemplateHaskell            #-}\n', '')
    props = re.findall(r'^(prop_\w+)\s*::', text, re.M)
    head = text[:text.index('\nreturn []\n')]
    main = ['', 'main :: IO ()', 'main = do',
            '  results <- sequence']
    for i, p in enumerate(props):
        main.append('    %s (putStrLn "=== %s ===" >> fmap isSuccess (quickCheckResult %s))'
                    % ('[' if i == 0 else ',', p, p))
    main += ['    ]', '  unless (and results) exitFailure', '']
    open(path, 'w').write(head + '\n'.join(main))


def setup():
    if os.path.isdir(WORK):
        shutil.rmtree(WORK)
    os.makedirs(WORK)
    for name, _ in PACKAGES:
        shutil.copytree(os.path.join(ROOT, 'ref', name, 'src'), WORK, dirs_exist_ok=True)
    tests = os.path.join(ROOT, 'ref', PACKAGES[0][0], 'tests')
    shutil.copytree(os.path.join(tests, 'Examples'), os.path.join(WORK, 'Examples'))
    shutil.copy(os.path.join(tests, 'test.hs'), WORK)
    # the golden help texts are read as tests/NAME.err.txt
    os.makedirs(os.path.join(WORK, 'tests'))
    for f in os.listdir(tests):
        if f.endswith('.err.txt'):
            shutil.copy(os.path.join(tests, f), os.path.join(WORK, 'tests'))
    adapt_test(os.path.join(WORK, 'test.hs'))


def run_yale(verbose):
    t = time.time()
    r = subprocess.run([YALE] + FLAGS + ['test.hs'], cwd=WORK,
                       capture_output=True, text=True, timeout=1800)
    if verbose:
        sys.stderr.write(r.stderr)
    return r.returncode, r.stdout, r.stderr, time.time() - t


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-v', action='store_true')
    args = ap.parse_args()
    fetch()
    setup()
    code, out, err, secs = run_yale(args.v)
    props = out.count('=== prop_')
    ok = out.count('+++ OK')
    if props > 0 and ok == props and code == 0:
        print('test.hs  %d of %d properties pass (%.1fs)' % (ok, props, secs))
        return 0
    print('test.hs  %d of %d properties pass (exit %d, %.1fs)' % (ok, props, code, secs))
    lines = out.splitlines()
    for i, l in enumerate(lines):
        if l.startswith('*** '):
            print('  ' + '\n  '.join(lines[max(0, i - 1):i + 6]))
            break
    if err.strip():
        print('  ' + '\n  '.join(err.strip().splitlines()[:15]))
    return 1


if __name__ == '__main__':
    sys.exit(main())
