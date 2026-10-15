#!/usr/bin/env python3
"""Copy scientific's Data.Scientific into lib/haskell98/ for Yale Haskell.

    tools/gen/import-scientific.py [SCIENTIFIC_DIR]

SCIENTIFIC_DIR is an unpacked scientific-0.3.8.0 (Hackage; BSD licence,
copied beside the module as LICENSE.scientific), by default
ref/scientific-0.3.8.0.  The module is patched, and a note at its top says
how:

  * no Binary instance and no Template Haskell Lift instance;
  * GHC.Integer's quotRemInteger, quotInteger and divInteger, and
    integer-logarithms' integerLog10', are defined in the module;
  * its Utils module is Data.Scientific.Utils (written for Yale Haskell:
    the powers of ten are a Data.Array rather than a primitive array);
  * the Read instance is readsPrec over ReadP (Yale's Read class has no
    readPrec);
  * PreludeModern is imported (a library sees the Haskell 98 Prelude).
"""

import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'ref', 'scientific-0.3.8.0')
OUT = os.path.join(ROOT, 'lib', 'haskell98', 'Data')

NOTE = """-- Data.Scientific from the scientific package, version 0.3.8.0 (BSD
-- licence: LICENSE.scientific), imported by tools/gen/import-scientific.py:
-- without the Binary and Lift instances, GHC.Integer's and
-- integer-logarithms' functions defined here, Utils as
-- Data.Scientific.Utils, and Read through readsPrec.  Edit the script, not
-- this file.
"""

LOCAL = """
-- (tools/gen/import-scientific.py) GHC.Integer and integer-logarithms
quotRemInteger :: Integer -> Integer -> (# Integer, Integer #)
quotRemInteger a b = case quotRem a b of (q, r) -> (# q, r #)

quotInteger, divInteger :: Integer -> Integer -> Integer
quotInteger = quot
divInteger = div

-- the integer part of the base-10 logarithm of a positive Integer
integerLog10' :: Integer -> Int
integerLog10' n = go 0 n
  where go acc m | m < 10 = acc
                 | m < 10000000000 = go (acc + 1) (m `quot` 10)
                 | otherwise = go (acc + 10) (m `quot` 10000000000)
"""

def patch(s):
    def rep(a, b):
        nonlocal s
        if a not in s:
            sys.exit('import-scientific: not found: ' + a[:60])
        s = s.replace(a, b, 1)
    rep('{-# LANGUAGE DeriveLift #-}\n', '')
    rep('import           Data.Binary                  (Binary, get, put)\n', '')
    rep('import           Math.NumberTheory.Logarithms (integerLog10\')\n', '')
    rep('import qualified Text.Read                       as Read\n', '')
    rep('import           Text.Read                        (readPrec)\n', '')
    rep('import qualified Text.ParserCombinators.ReadPrec as ReadPrec\n', '')
    rep('import GHC.Integer.Compat (quotRemInteger, quotInteger, divInteger)\n', '')
    rep('import Utils              (maxExpt, roundTo, magnitude)\n',
        'import Data.Scientific.Utils (maxExpt, roundTo, magnitude)\n')
    rep('import Language.Haskell.TH.Syntax (Lift (..))\n', '')
    # base's Prelude names (<$>, <*>, ...): a library is compiled with the
    # Haskell 98 Prelude
    rep('import           Control.Exception ',
        'import           PreludeModern (Applicative(..), (<$>), (<$))\nimport           Control.Exception ')
    rep('-- | @since 0.3.7.0\nderiving instance Lift Scientific\n', '')
    i = s.index('-- | Note that in the future I intend to change the type of the')
    j = s.index('-- | Scientific numbers can be safely compared for equality.')
    s = s[:i] + s[j:]
    rep('    readPrec = Read.parens $ ReadPrec.lift (ReadP.skipSpaces >> scientificP)',
        '    readsPrec _ = readParen False (ReadP.readP_to_S (ReadP.skipSpaces >> scientificP))')
    i = s.index('\n----------------------------------------------------------------------\n-- Instances')
    s = s[:i] + LOCAL + s[i:]
    return NOTE + s

def main():
    s = open(os.path.join(SRC, 'src', 'Data', 'Scientific.hs')).read()
    open(os.path.join(OUT, 'Scientific.hs'), 'w').write(patch(s))
    with open(os.path.join(OUT, 'Scientific.hu'), 'w') as f:
        f.write(':output $LIBRARYBIN/Data/\n:o= all\nScientific.hs\n')
    shutil.copy(os.path.join(SRC, 'LICENSE'), os.path.join(OUT, 'LICENSE.scientific'))

if __name__ == '__main__':
    main()
