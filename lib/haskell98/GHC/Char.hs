-- GHC.Char (base): chr and the Char comparisons.
module GHC.Char (chr, eqChar, neChar) where

import Data.Char (chr)

eqChar, neChar :: Char -> Char -> Bool
eqChar = (==)
neChar = (/=)
