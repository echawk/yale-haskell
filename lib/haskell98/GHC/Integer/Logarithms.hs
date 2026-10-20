{-# LANGUAGE MagicHash #-}
-- GHC.Integer.Logarithms (integer-gmp's compatibility module): floor
-- logarithms of positive numbers.  Int# and Word# are Int and Word
-- (GHC.Exts).
module GHC.Integer.Logarithms (integerLog2#, integerLogBase#, wordLog2#) where

import GHC.Exts (Int#, Word#)

-- | The floor of the base-2 logarithm of a positive Integer.
integerLog2# :: Integer -> Int#
integerLog2# = integerLogBase# 2

-- | The floor of the logarithm of a positive Integer in a base > 1.
integerLogBase# :: Integer -> Integer -> Int#
integerLogBase# b i
  | i < b = 0
  | otherwise = doDiv (i `div` (b ^ l)) l
  where
    -- the Haskell report's integerLogBase: square the base first
    l = 2 * integerLogBase# (b * b) i
    doDiv x n | x < b = n
              | otherwise = doDiv (x `div` b) (n + 1)

-- | The floor of the base-2 logarithm of a nonzero Word; -1 for 0.
wordLog2# :: Word# -> Int#
wordLog2# 0 = -1
wordLog2# w = integerLog2# (toInteger w)
