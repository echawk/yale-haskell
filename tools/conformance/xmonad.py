#!/usr/bin/env python3
"""Run xmonad's QuickCheck properties (its pure core) under Yale Haskell.

    tools/conformance/xmonad.py [-v]

xmonad 0.18.1 (BSD licence) is fetched into ref/ and its test suite
(tests/Properties*.hs, about 1,800 lines over XMonad.StackSet) is run with
`yale-haskell --haskell98 --modern-prelude`.  Without an X server three
things are adapted, in the build copy only:

- Graphics.X11 and Graphics.X11.Xlib.Types are a types-only stand-in
  (tools/conformance/xmonad/Graphics, the X11 package's Rectangle);
- XMonad.Operations and XMonad.Layout are reduced to the pure functions
  the properties use (pointWithin, the size hints, mirrorRect), extracted
  verbatim from xmonad's source;
- the properties of Properties/Layout/ (they need XMonad.Core and the X
  monad) and the Foldable/Traversable laws from quickcheck-classes (they
  need QuantifiedConstraints) are left out: 107 properties remain.

The output is compared with GHC 9.14's on the same sources
(tools/conformance/xmonad/expected.out) after replacing the discarded-case
counts, which depend on the random generator.
"""

import argparse
import glob
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
HERE = os.path.join(ROOT, 'tools', 'conformance', 'xmonad')
REF = os.path.join(ROOT, 'ref', 'xmonad-0.18.1')
WORK = os.path.join(ROOT, 'build', 'conformance', 'xmonad')
YALE = os.path.join(ROOT, 'bin', 'yale-haskell')
URL = 'https://hackage.haskell.org/package/xmonad-0.18.1/xmonad-0.18.1.tar.gz'
SHA256 = '988b5f3104ac03aa078248afea7efcaed86661dfb239efd44995f58cd4f7a1f0'


def fetch():
    if os.path.isdir(REF):
        return
    tmp = REF + '.tar.gz'
    urllib.request.urlretrieve(URL, tmp)
    with open(tmp, 'rb') as f:
        if hashlib.sha256(f.read()).hexdigest() != SHA256:
            sys.exit('xmonad-0.18.1.tar.gz is not the version expected')
    with tarfile.open(tmp) as t:
        t.extractall(os.path.dirname(REF), filter='data')
    os.remove(tmp)


def extract(path, names):
    """The definitions NAMES (a signature or `type' line and the lines
    indented under it, and further equations) from the module at PATH."""
    lines = open(path).read().split('\n')
    out = []
    for n in names:
        i = next(k for k, l in enumerate(lines) if l.startswith(n + ' '))
        j = i + 1
        while j < len(lines) and (lines[j].startswith(' ')
                                  or lines[j].startswith(n.split()[-1] + ' ')):
            j += 1
        out += lines[i:j] + ['']
    return '\n'.join(out)


def setup():
    if os.path.isdir(WORK):
        shutil.rmtree(WORK)
    os.makedirs(os.path.join(WORK, 'XMonad'))
    shutil.copy(os.path.join(REF, 'src', 'XMonad', 'StackSet.hs'),
                os.path.join(WORK, 'XMonad'))
    shutil.copytree(os.path.join(REF, 'tests'), WORK, dirs_exist_ok=True)
    shutil.copytree(os.path.join(HERE, 'Graphics'), os.path.join(WORK, 'Graphics'))
    # the Layout properties and the quickcheck-classes laws
    layout = set()
    for f in glob.glob(os.path.join(REF, 'tests', 'Properties', 'Layout', '*.hs')):
        layout |= set(re.findall(r'^(prop_\w+)', open(f).read(), re.M))
    shutil.rmtree(os.path.join(WORK, 'Properties', 'Layout'))
    p = os.path.join(WORK, 'Properties.hs')
    s = open(p).read()
    s = s.replace('import Properties.Layout.Full\n', '').replace('import Properties.Layout.Tall\n', '')
    s = '\n'.join(l for l in s.split('\n')
                  if not (l.strip().startswith((',(', '[('))
                          and any(re.search(r'\b%s\b' % n, l) for n in layout)))
    s = re.sub(r'\]\s*<>\s*\n\s*prop_laws_Stack', ']', s)
    open(p, 'w').write(s)
    p = os.path.join(WORK, 'Properties', 'Stack.hs')
    s = open(p).read()
    s = re.sub(r'import Data.Proxy\nimport Test.QuickCheck.Classes \(\n.*?\)\n', '', s, flags=re.S)
    s = s[:s.index('-- Check type class laws')]
    open(p, 'w').write(s)
    src = os.path.join(REF, 'src', 'XMonad')
    open(os.path.join(WORK, 'XMonad', 'Operations.hs'), 'w').write(
        '-- XMonad.Operations: only its pure size-hint and geometry functions,\n'
        '-- extracted from xmonad\'s source by tools/conformance/xmonad.py.\n'
        'module XMonad.Operations (pointWithin, applyAspectHint, applyResizeIncHint,'
        ' applyMaxSizeHint) where\n\nimport Graphics.X11.Xlib.Types\n\n'
        + extract(os.path.join(src, 'Operations.hs'),
                  ['type D', 'pointWithin', 'applyAspectHint',
                   'applyResizeIncHint', 'applyMaxSizeHint']))
    open(os.path.join(WORK, 'XMonad', 'Layout.hs'), 'w').write(
        '-- XMonad.Layout: only mirrorRect, extracted from xmonad\'s source by\n'
        '-- tools/conformance/xmonad.py.\n'
        'module XMonad.Layout (mirrorRect) where\n\nimport Graphics.X11.Xlib.Types\n\n'
        + extract(os.path.join(src, 'Layout.hs'), ['mirrorRect']))


def normalize(text):
    return re.sub(r'; \d+ discarded\.', '; N discarded.', text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-v', action='store_true')
    a = ap.parse_args()
    fetch()
    setup()
    start = time.time()
    p = subprocess.run([YALE, '--haskell98', '--modern-prelude', 'Properties.hs'],
                       cwd=WORK, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    secs = time.time() - start
    out = normalize(p.stdout.decode('utf-8', 'replace'))
    want = open(os.path.join(HERE, 'expected.out')).read()
    got_lines, want_lines = out.splitlines(), want.splitlines()
    ok = sum(1 for g, w in zip(got_lines, want_lines) if g == w)
    print('%d of %d properties match GHC (%.1fs, including compilation)'
          % (ok, len(want_lines), secs))
    if out != want:
        if a.v:
            for g, w in zip(got_lines + ['<end>'] * len(want_lines), want_lines):
                if g != w:
                    print('  got  %r\n  want %r' % (g, w))
            print(p.stderr.decode('utf-8', 'replace')[-2000:])
        sys.exit(1)


if __name__ == '__main__':
    main()
