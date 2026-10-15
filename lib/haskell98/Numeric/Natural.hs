-- Numeric.Natural (base): non-negative integers, an Integer underneath.
-- A result below zero is the error GHC raises, "arithmetic underflow".
module Numeric.Natural (Natural, minusNaturalMaybe) where

import Data.Ix (Ix(..))
import Data.Bits (Bits(..))
import Control.Exception (throw, ArithException(Underflow))

newtype Natural = Natural Integer

underflow :: a
underflow = throw Underflow

natural :: Integer -> Natural
natural n = if n < 0 then underflow else Natural n

instance Eq Natural where
  Natural a == Natural b = a == b
instance Ord Natural where
  compare (Natural a) (Natural b) = compare a b
instance Show Natural where
  showsPrec p (Natural n) = showsPrec p n
instance Read Natural where
  readsPrec p s = [(natural n, r) | (n, r) <- readsPrec p s]
instance Num Natural where
  Natural a + Natural b = Natural (a + b)
  Natural a - Natural b = natural (a - b)
  Natural a * Natural b = Natural (a * b)
  negate (Natural 0) = Natural 0
  negate _ = underflow
  abs n = n
  signum (Natural n) = Natural (signum n)
  fromInteger = natural
instance Real Natural where
  toRational (Natural n) = toRational n
instance Enum Natural where
  toEnum = natural . toInteger
  fromEnum (Natural n) = fromInteger n
  succ (Natural n) = Natural (n + 1)
  pred (Natural n) = natural (n - 1)
  enumFrom (Natural n) = map Natural (enumFrom n)
  enumFromThen (Natural a) (Natural b)
    | b >= a = map Natural (enumFromThen a b)
    | otherwise = map Natural (enumFromThenTo a b 0)
  enumFromTo (Natural a) (Natural b) = map Natural (enumFromTo a b)
  enumFromThenTo (Natural a) (Natural b) (Natural c) = map Natural (enumFromThenTo a b c)
instance Integral Natural where
  toInteger (Natural n) = n
  quotRem (Natural a) (Natural b) = let (q, r) = quotRem a b in (Natural q, Natural r)
  divMod (Natural a) (Natural b) = let (q, r) = divMod a b in (Natural q, Natural r)
instance Ix Natural where
  range (Natural a, Natural b) = map Natural (range (a, b))
  index (Natural a, Natural b) (Natural i) = index (a, b) i
  inRange (Natural a, Natural b) (Natural i) = inRange (a, b) i
instance Bits Natural where
  Natural a .&. Natural b = Natural (a .&. b)
  Natural a .|. Natural b = Natural (a .|. b)
  xor (Natural a) (Natural b) = Natural (xor a b)
  complement _ = error "Bits.complement: Natural complement undefined"
  shift (Natural a) i = Natural (shift a i)
  rotate (Natural a) i = Natural (shift a i)
  bit i = Natural (bit i)
  testBit (Natural a) i = testBit a i
  bitSize _ = error "Data.Bits.bitSize(Natural)"
  bitSizeMaybe _ = Nothing
  isSigned _ = False
  popCount (Natural a) = popCount a

minusNaturalMaybe :: Natural -> Natural -> Maybe Natural
minusNaturalMaybe (Natural a) (Natural b) = if a >= b then Just (Natural (a - b)) else Nothing
