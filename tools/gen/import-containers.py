#!/usr/bin/env python3
"""Install the containers package's source in Yale Haskell's library.

    tools/gen/import-containers.py CONTAINERS-DIR

CONTAINERS-DIR is an unpacked containers release from Hackage (0.8.1:
tools/microcabal/mcabal fetch containers puts it in
build/mcabal/packages/containers-0.8.1).  Its modules are copied
unchanged into lib/haskell98, each with a unit file marked :package (a
port of a package written against GHC's base, compiled with base's
Prelude in every mode: src/compiler/top/globals.mumble), replacing the
older containers modules there.  include/containers.h goes to
lib/haskell98/include with one change: Yale Haskell defines
DEFINE_PATTERN_SYNONYMS, as GHC and MicroHs do (Seq's Empty, :<|, :|>).
"""
import os, re, shutil, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIB = os.path.join(ROOT, 'lib', 'haskell98')

# the older containers modules (0.3, nhc98's) that the release replaces
OLD = ['Data/Map.hs', 'Data/Map', 'Data/IntMap.hs', 'Data/IntMap', 'Data/Set.hs',
       'Data/IntSet.hs', 'Data/Sequence.hs', 'Data/Tree.hs', 'Data/Graph.hs']


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    src_root = sys.argv[1]
    src = os.path.join(src_root, 'src')
    m = re.search(r'^version:\s*(\S+)', open(os.path.join(src_root, 'containers.cabal')).read(), re.M)
    version = m.group(1) if m else '?'
    for old in OLD:
        path = os.path.join(LIB, old)
        if os.path.isdir(path):
            shutil.rmtree(path)
        elif os.path.exists(path):
            os.remove(path)
            hu = path[:-3] + '.hu'
            if os.path.exists(hu):
                os.remove(hu)
    n = 0
    for dirpath, _, files in os.walk(src):
        for f in sorted(files):
            if not f.endswith('.hs'):
                continue
            rel = os.path.relpath(os.path.join(dirpath, f), src)
            dest = os.path.join(LIB, rel)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            shutil.copyfile(os.path.join(dirpath, f), dest)
            reldir = os.path.dirname(rel)
            with open(dest[:-3] + '.hu', 'w') as hu:
                hu.write(':output $LIBRARYBIN/%s\n:o= all\n:package\n%s\n'
                         % (reldir + '/' if reldir else '', f))
            n += 1
    header = open(os.path.join(src_root, 'include', 'containers.h')).read()
    patched = header.replace(
        '#if defined(__GLASGOW_HASKELL__) || defined(__MHS__)\n#define DEFINE_PATTERN_SYNONYMS 1',
        '#if defined(__GLASGOW_HASKELL__) || defined(__MHS__) || defined(__YALE_HASKELL__)\n'
        '#define DEFINE_PATTERN_SYNONYMS 1')
    if patched == header:
        sys.exit('containers.h: the DEFINE_PATTERN_SYNONYMS condition was not found')
    os.makedirs(os.path.join(LIB, 'include'), exist_ok=True)
    with open(os.path.join(LIB, 'include', 'containers.h'), 'w') as f:
        f.write('/* containers %s\'s include/containers.h, with Yale Haskell added to the\n'
                '   DEFINE_PATTERN_SYNONYMS condition (tools/gen/import-containers.py). */\n'
                % version)
        f.write(patched)
    shutil.copyfile(os.path.join(src_root, 'LICENSE'), os.path.join(LIB, 'Data', 'LICENSE.containers'))
    print('containers %s: %d modules into lib/haskell98' % (version, n))


if __name__ == '__main__':
    main()
