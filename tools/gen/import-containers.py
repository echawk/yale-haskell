#!/usr/bin/env python3
"""Copy the containers package's modules into lib/haskell98/Data/.

    tools/gen/import-containers.py [CONTAINERS_DIR]

CONTAINERS_DIR is containers 0.3.0.0 as nhc98 ships it (Haskell 98 with
CPP), by default ~/hs/nhc98/src/libraries/containers.  Each module is
patched for Yale Haskell, and a note at its top says how:

  * {-# LANGUAGE CPP #-}: the package turns CPP on in its .cabal file.
  * Data.Typeable is left out (Yale Haskell has none): its imports, and
    the Typeable instances made by include/Typeable.h's macros.
  * A Semigroup instance beside each Monoid one: Monoid's superclass, as
    in today's base (PreludeModern).
  * Data.Sequence hides Data.Foldable's length and null, methods since
    base 4.8, as it defines its own.

The package's LICENSE (BSD) is copied as lib/haskell98/Data/LICENSE.containers.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser(
    '~/hs/nhc98/src/libraries/containers')
OUT = os.path.join(ROOT, 'lib', 'haskell98', 'Data')
MODULES = ['Map', 'Set', 'IntMap', 'IntSet', 'Sequence', 'Tree']

NOTE = """{-# LANGUAGE CPP #-}
-- Data.%s from the containers package, version 0.3.0.0 (BSD license:
-- LICENSE.containers), as nhc98 ships it, imported by
-- tools/gen/import-containers.py: without Data.Typeable, and with a
-- Semigroup instance beside the Monoid one.  Edit the script, not this file.

"""


def patch(name, src):
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
    if name == 'Sequence':
        src = re.sub(r'^import Data\.Foldable$',
                     'import Data.Foldable hiding (length, null)', src, flags=re.M)
    return NOTE % name + src


def main():
    for name in MODULES:
        with open(os.path.join(SRC, 'Data', name + '.hs'), encoding='latin-1') as f:
            src = f.read()
        out = patch(name, src)
        with open(os.path.join(OUT, name + '.hs'), 'w', encoding='latin-1') as f:
            f.write(out)
        with open(os.path.join(OUT, name + '.hu'), 'w') as f:
            f.write(':output $LIBRARYBIN/Data/\n:o= all\n%s.hs\n' % name)
        print('lib/haskell98/Data/%s.hs' % name)
    with open(os.path.join(SRC, 'LICENSE'), encoding='latin-1') as f:
        lic = f.read()
    with open(os.path.join(OUT, 'LICENSE.containers'), 'w', encoding='latin-1') as f:
        f.write(lic)


main()
