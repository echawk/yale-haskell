-- GHC.Fingerprint.Type (base): a 128-bit fingerprint.
module GHC.Fingerprint.Type (Fingerprint(..)) where

import Data.Word (Word64)
import Numeric (showHex)

data Fingerprint = Fingerprint Word64 Word64
  deriving (Eq, Ord)

instance Show Fingerprint where
  show (Fingerprint w1 w2) = hex16 w1 ++ hex16 w2
    where hex16 i = let hex = showHex i "" in replicate (16 - length hex) '0' ++ hex
