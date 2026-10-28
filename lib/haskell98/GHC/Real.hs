{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
-- GHC.Real (base): Ratio's constructor (:%) and the numeric classes'
-- functions.  Yale Haskell's Ratio is abstract (PreludeRatio's): x :% y
-- matches a ratio's numerator and denominator, and builds x % y (the
-- same ratio when x :% y is reduced, as base's are).
module GHC.Real (
    Ratio, Rational, pattern (:%), (%), numerator, denominator, reduce,
    Real(..), Integral(..), Fractional(..), RealFrac(..),
    fromIntegral, realToFrac, (^), (^^), gcd, lcm, even, odd,
    showSigned, numericEnumFrom, numericEnumFromThen, numericEnumFromTo,
    numericEnumFromThenTo, integralEnumFrom, integralEnumFromTo
  ) where

import Data.Ratio (Ratio, (%), numerator, denominator)
import Numeric (showSigned)

infixl 7 :%

pattern (:%) :: Integral a => a -> a -> Ratio a
pattern x :% y <- (ratioParts -> (x, y))
  where x :% y = x % y

ratioParts :: Integral a => Ratio a -> (a, a)
ratioParts r = (numerator r, denominator r)

reduce :: Integral a => a -> a -> Ratio a
reduce = (%)

numericEnumFrom :: Fractional a => a -> [a]
numericEnumFrom n = n : numericEnumFrom (n + 1)

numericEnumFromThen :: Fractional a => a -> a -> [a]
numericEnumFromThen n m = n : numericEnumFromThen m (m + m - n)

numericEnumFromTo :: (Ord a, Fractional a) => a -> a -> [a]
numericEnumFromTo n m = takeWhile (<= m + 1 / 2) (numericEnumFrom n)

numericEnumFromThenTo :: (Ord a, Fractional a) => a -> a -> a -> [a]
numericEnumFromThenTo e1 e2 e3 = takeWhile p (numericEnumFromThen e1 e2)
  where mid = (e2 - e1) / 2
        p x | e2 >= e1 = x <= e3 + mid
            | otherwise = x >= e3 + mid

integralEnumFrom :: (Integral a, Bounded a) => a -> [a]
integralEnumFrom n = [n .. maxBound]

integralEnumFromTo :: Integral a => a -> a -> [a]
integralEnumFromTo n m = [n .. m]
