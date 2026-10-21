{-# LANGUAGE MagicHash, UnboxedTuples #-}
-- GHC.Integer (integer-gmp's compatibility module): Integer arithmetic
-- under its primitive names.  Unboxed tuples are ordinary tuples here.
module GHC.Integer
  ( Integer, smallInteger, integerToInt
  , plusInteger, minusInteger, timesInteger, negateInteger, absInteger
  , signumInteger, eqInteger, neqInteger, leInteger, gtInteger, ltInteger
  , geInteger, compareInteger
  , quotInteger, remInteger, divInteger, modInteger
  , quotRemInteger, divModInteger
  ) where

smallInteger :: Int -> Integer
smallInteger = toInteger

integerToInt :: Integer -> Int
integerToInt = fromInteger

plusInteger, minusInteger, timesInteger :: Integer -> Integer -> Integer
plusInteger = (+)
minusInteger = (-)
timesInteger = (*)

negateInteger, absInteger, signumInteger :: Integer -> Integer
negateInteger = negate
absInteger = abs
signumInteger = signum

eqInteger, neqInteger, leInteger, gtInteger, ltInteger, geInteger
  :: Integer -> Integer -> Bool
eqInteger = (==)
neqInteger = (/=)
leInteger = (<=)
gtInteger = (>)
ltInteger = (<)
geInteger = (>=)

compareInteger :: Integer -> Integer -> Ordering
compareInteger = compare

quotInteger, remInteger, divInteger, modInteger :: Integer -> Integer -> Integer
quotInteger = quot
remInteger = rem
divInteger = div
modInteger = mod

quotRemInteger, divModInteger :: Integer -> Integer -> (# Integer, Integer #)
quotRemInteger n d = case quotRem n d of (q, r) -> (# q, r #)
divModInteger n d = case divMod n d of (q, r) -> (# q, r #)
