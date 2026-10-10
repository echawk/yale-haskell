#!/usr/bin/env python3
"""Copy library modules nhc98 ships (Haskell 98, some with CPP) into
lib/haskell98/.

    tools/gen/import-nhc98-libs.py [NHC98_LIBRARIES_DIR]

NHC98_LIBRARIES_DIR is nhc98's src/libraries, by default
~/hs/nhc98/src/libraries.  The modules (MODULES below):
  * containers 0.3.0.0: Data.Map, Set, IntMap, IntSet, Sequence, Tree;
  * base: Text.Printf;
  * pretty: Text.PrettyPrint, Text.PrettyPrint.HughesPJ.
Each package's LICENSE (all BSD) is copied beside its modules.

The containers modules are patched for Yale Haskell, and a note at the top
of each module says how:

  * {-# LANGUAGE CPP #-}: the package turns CPP on in its .cabal file.
  * Data.Typeable is left out (Yale Haskell has none): its imports, and
    the Typeable instances made by include/Typeable.h's macros.
  * A Semigroup instance beside each Monoid one: Monoid's superclass, as
    in today's base (PreludeModern).
  * Data.Sequence hides Data.Foldable's length and null, methods since
    base 4.8, as it defines its own.
  * Map, IntMap, Set and IntSet get the folds of newer containers they
    lack (foldrWithKey, foldlWithKey', foldr', ...), through toAscList.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIBS = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser(
    '~/hs/nhc98/src/libraries')
OUT = os.path.join(ROOT, 'lib', 'haskell98')

# (package, module): the package's version is in its .cabal file
MODULES = [('containers', 'Data.' + m)
           for m in ['Map', 'Set', 'IntMap', 'IntSet', 'Sequence', 'Tree']] + [
    ('base', 'Text.Printf'),
    ('pretty', 'Text.PrettyPrint'),
    ('pretty', 'Text.PrettyPrint.HughesPJ'),
]

CONTAINERS_NOTE = """{-# LANGUAGE CPP #-}
-- %s from the containers package, version 0.3.0.0 (BSD license:
-- LICENSE.containers), as nhc98 ships it, imported by
-- tools/gen/import-nhc98-libs.py: without Data.Typeable, and with a
-- Semigroup instance beside the Monoid one.  Edit the script, not this file.

"""

NOTE = """-- %s from nhc98's %s package (BSD license: LICENSE.%s), imported
-- by tools/gen/import-nhc98-libs.py.  Edit the script, not this file.

"""


def patch_containers(name, src):
    # Typeable: the imports (one or more lines) and the macro instances
    src = re.sub(r'^import Data\.Typeable\b[^\n]*(\n[ \t]+[^\n]*)*\n', '', src, flags=re.M)
    src = re.sub(r'^#include "Typeable\.h"\n', '', src, flags=re.M)
    src = re.sub(r'^INSTANCE_TYPEABLE\d\([^\n]*\)\n', '', src, flags=re.M)
    # a Semigroup instance for each Monoid one
    def semigroup(m):
        head = m.group(1)
        return ('instance %sSemigroup %s where\n    (<>) = mappend\n\n%s'
                % (head, m.group(2), m.group(0)))
    src, n = re.subn(r'^instance ((?:\([^)]*\) =>|\w+ \w+ =>)? ?)Monoid ([^\n]*?) where\n'
                     r'(?=(?:    |\t)mempty)', semigroup, src, flags=re.M)
    if n:
        # Semigroup's (<>) comes from PreludeModern, next to Monoid
        src = re.sub(r'^import Data\.Monoid \(Monoid\(\.\.\)\)$',
                     'import Data.Monoid (Monoid(..))\nimport PreludeModern (Semigroup((<>)))',
                     src, count=1, flags=re.M)
    # base 4.2's Foldable had no length or null methods; Data.Sequence
    # defines its own
    if name == 'Data.Sequence':
        src = re.sub(r'^import Data\.Foldable$',
                     'import Data.Foldable hiding (length, null)', src, flags=re.M)
    src = add_newer_folds(name, src)
    return CONTAINERS_NOTE % name + src


# Folds newer containers have, defined through the ascending list (the
# module's own toAscList/elems), for the modules that lack them.
KEYED_FOLDS = {
    'foldr': 'foldr f z m = YaleList.foldr f z (elems m)',
    'foldl': 'foldl f z m = YaleList.foldl f z (elems m)',
    "foldr'": "foldr' f z m = YaleList.foldr f z (elems m)",
    "foldl'": "foldl' f z m = YaleList.foldl' f z (elems m)",
    'foldrWithKey': 'foldrWithKey f z m = YaleList.foldr (\\(k, v) acc -> f k v acc) z (toAscList m)',
    'foldlWithKey': 'foldlWithKey f z m = YaleList.foldl (\\acc (k, v) -> f acc k v) z (toAscList m)',
    "foldrWithKey'": "foldrWithKey' f z m = YaleList.foldr (\\(k, v) acc -> f k v acc) z (toAscList m)",
    "foldlWithKey'": "foldlWithKey' f z m = YaleList.foldl' (\\acc (k, v) -> f acc k v) z (toAscList m)",
}
SET_FOLDS = {
    'foldr': 'foldr f z s = YaleList.foldr f z (toAscList s)',
    'foldl': 'foldl f z s = YaleList.foldl f z (toAscList s)',
    "foldr'": "foldr' f z s = YaleList.foldr f z (toAscList s)",
    "foldl'": "foldl' f z s = YaleList.foldl' f z (toAscList s)",
}

def add_newer_folds(name, src):
    folds = {'Data.Map': KEYED_FOLDS, 'Data.IntMap': KEYED_FOLDS,
             'Data.Set': SET_FOLDS, 'Data.IntSet': SET_FOLDS}.get(name)
    if not folds:
        return src
    missing = [f for f in folds if not re.search(r'^' + re.escape(f) + r'\s', src, re.M)]
    if not missing:
        return src
    src = src.replace('module %s ' % name, 'module %s ' % name, 1)
    src = re.sub(r'^(module ' + re.escape(name) + r'\s*\()', r'\1 ' + ', '.join(missing) + ',',
                 src, count=1, flags=re.M)
    # the first import, then (once) the qualified list module
    src = re.sub(r'^import ', 'import qualified Data.List as YaleList\nimport ', src,
                 count=1, flags=re.M)
    defs = '\n'.join(folds[f] for f in missing)
    return src + ('\n\n-- Folds of newer containers (tools/gen/import-nhc98-libs.py)\n'
                  + defs + '\n')


def main():
    licenses = {}
    for pkg, mod in MODULES:
        path = mod.replace('.', '/')
        with open(os.path.join(LIBS, pkg, path + '.hs'), encoding='latin-1') as f:
            src = f.read()
        if pkg == 'containers':
            out = patch_containers(mod, src)
        else:
            out = NOTE % (mod, pkg, pkg) + src
        dest = os.path.join(OUT, path + '.hs')
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, 'w', encoding='latin-1') as f:
            f.write(out)
        with open(os.path.join(OUT, path + '.hu'), 'w') as f:
            f.write(':output $LIBRARYBIN/%s\n:o= all\n%s.hs\n'
                    % (os.path.dirname(path) + '/', os.path.basename(path)))
        print('lib/haskell98/%s.hs' % path)
        licenses[pkg] = os.path.dirname(dest)
    for pkg, d in licenses.items():
        with open(os.path.join(LIBS, pkg, 'LICENSE'), encoding='latin-1') as f:
            lic = f.read()
        with open(os.path.join(d, 'LICENSE.' + pkg), 'w', encoding='latin-1') as f:
            f.write(lic)


main()
