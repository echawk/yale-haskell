#!/usr/bin/env python3
"""Run happy, the parser generator, under Yale Haskell.

    tools/conformance/happy.py [-v] [--record GHC-HAPPY] [GRAMMAR ...]

happy 1.20.1.1 (BSD licence; about 7,000 lines: mtl, containers, arrays,
and its own happy-generated GHC-style parsers with MagicHash) is fetched
into ref/ and runs unchanged as

    yale-haskell --haskell98 --modern-prelude --cpp -D__GLASGOW_HASKELL__=914
                 Main.lhs

with only Cabal's Paths_happy supplied (tools/conformance/happy/).  It is
run on happy's test and example grammars with the flag sets of happy's
own test suite (none, -a, -g, -gc, -gac), and each generated parser, its
grammar info file (--info) and its messages are compared, by SHA-256,
with GHC 9.14's happy on the same sources (tools/conformance/happy/
expected.sha256; --record writes it from a GHC-built happy).

issue93.y (a 1,250-line grammar) is a performance guard: GHC's happy takes
8 s; Yale's once took over an hour, from the optimizer moving a memo
table into a lambda (let-hoist-lambda) and the Report's O(n^2) sortBy.
It runs with a time limit (ISSUE93_LIMIT seconds, default 600).
"""

import argparse
import glob
import hashlib
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HERE = os.path.join(ROOT, 'tools', 'conformance', 'happy')
REF = os.path.join(ROOT, 'ref', 'happy-1.20.1.1')
WORK = os.path.join(ROOT, 'build', 'conformance', 'happy')
YALE = os.path.join(ROOT, 'bin', 'yale-haskell')
URL = 'https://hackage.haskell.org/package/happy-1.20.1.1/happy-1.20.1.1.tar.gz'
SHA256 = '8b4e7dc5a6c5fd666f8f7163232931ab28746d0d17da8fa1cbd68be9e878881b'
FLAGS = ['', '-a', '-g', '-gc', '-gac']
LIMIT = 300
ISSUE93_LIMIT = float(os.environ.get('ISSUE93_LIMIT', '600'))


def fetch():
    if os.path.isdir(REF):
        return
    tmp = REF + '.tar.gz'
    urllib.request.urlretrieve(URL, tmp)
    with open(tmp, 'rb') as f:
        if hashlib.sha256(f.read()).hexdigest() != SHA256:
            sys.exit('happy-1.20.1.1.tar.gz is not the version expected')
    with tarfile.open(tmp) as t:
        t.extractall(os.path.dirname(REF), filter='data')
    os.remove(tmp)


def setup():
    if os.path.isdir(WORK):
        shutil.rmtree(WORK)
    shutil.copytree(os.path.join(REF, 'src'), WORK)
    shutil.copy(os.path.join(HERE, 'Paths_happy.hs'), WORK)


def grammars():
    return (sorted(glob.glob(os.path.join(REF, 'tests', '*.y')))
            + sorted(glob.glob(os.path.join(REF, 'tests', '*.ly')))
            + sorted(glob.glob(os.path.join(REF, 'examples', '*.ly'))))


def yale_happy():
    return [YALE, '--haskell98', '--modern-prelude', '--cpp', '-D__GLASGOW_HASKELL__=914',
            '-I', os.path.join(ROOT, 'tools', 'conformance', 'cubicaltt', 'include'),
            os.path.join(WORK, 'Main.lhs')]


def run(cmd, grammar, flags, limit):
    """The digest of what happy produces for GRAMMAR with FLAGS, or None
    when it runs out of time."""
    d = tempfile.mkdtemp(prefix='happy-')
    env = dict(os.environ, happy_datadir=os.path.join(REF, 'data'))
    args = cmd + ([flags] if flags else []) + ['--strict', grammar, '-o', 'out.hs',
                                               '--info=out.info']
    try:
        p = subprocess.run(args, cwd=d, env=env, stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT, timeout=limit)
    except subprocess.TimeoutExpired:
        shutil.rmtree(d)
        return None
    h = hashlib.sha256()
    # the program's name in its messages: happy, or Main under Yale
    h.update(p.stdout.replace(b'Main:', b'happy:'))
    h.update(b'exit %d' % (p.returncode != 0))
    for f in ('out.hs', 'out.info'):
        path = os.path.join(d, f)
        h.update(open(path, 'rb').read() if os.path.exists(path) else b'<none>')
    shutil.rmtree(d)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-v', action='store_true')
    ap.add_argument('--record', metavar='GHC-HAPPY')
    ap.add_argument('grammars', nargs='*')
    a = ap.parse_args()
    fetch()
    manifest = os.path.join(HERE, 'expected.sha256')
    names = a.grammars or [os.path.relpath(g, REF) for g in grammars()]
    if a.record:
        with open(manifest, 'w') as out:
            for n in names:
                for fl in FLAGS:
                    out.write('%s %s %s\n' % (run([a.record], os.path.join(REF, n), fl, 3600),
                                              n, fl or '-'))
        return
    setup()
    start = time.time()
    p = subprocess.run(yale_happy() + ['--version'], stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT)
    if p.returncode != 0:
        print(p.stdout.decode('utf-8', 'replace')[-3000:])
        sys.exit('happy did not compile')
    print('happy compiled (%.0fs)' % (time.time() - start))
    want = {}
    for line in open(manifest):
        digest, n, fl = line.split()
        want[(n, '' if fl == '-' else fl)] = digest
    ok = bad = 0
    for n in names:
        large = os.path.basename(n) == 'issue93.y'
        for fl in (FLAGS if not large else ['']):
            start = time.time()
            got = run(yale_happy(), os.path.join(REF, n), fl, ISSUE93_LIMIT if large else LIMIT)
            secs = time.time() - start
            if got == want.get((n, fl)):
                ok += 1
                if a.v or large:
                    print('pass  %-28s %-5s %.1fs' % (n, fl, secs))
            else:
                bad += 1
                print('%s  %-28s %-5s %.1fs' % ('TIME' if got is None else 'FAIL', n, fl, secs))
    print('%d of %d outputs match GHC' % (ok, ok + bad))
    if bad:
        sys.exit(1)


if __name__ == '__main__':
    main()
