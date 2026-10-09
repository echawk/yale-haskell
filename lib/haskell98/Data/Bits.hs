-- Data.Bits: the Haskell 2010 library module (Report 2010, chapter 14),
-- for Yale Haskell's Haskell 98 dialect.  Instances for Int (a fixnum:
-- bitSize is 63 on 64-bit SBCL, and shifts wrap at that width) and
-- Integer (no bitSize; shifts are exact).
module Data.Bits (
    Bits((.&.), (.|.), xor, complement, shift, rotate, bit, setBit,
         clearBit, complementBit, testBit, bitSize, isSigned,
         shiftL, shiftR, rotateL, rotateR, popCount)
  ) where

import BitsPrims

infixl 8 `shift`, `rotate`, `shiftL`, `shiftR`, `rotateL`, `rotateR`
infixl 7 .&.
infixl 6 `xor`
infixl 5 .|.

class Num a => Bits a where
  (.&.), (.|.), xor :: a -> a -> a
  complement        :: a -> a
  shift             :: a -> Int -> a
  rotate            :: a -> Int -> a
  bit               :: Int -> a
  setBit, clearBit, complementBit :: a -> Int -> a
  testBit           :: a -> Int -> Bool
  bitSize           :: a -> Int
  isSigned          :: a -> Bool
  shiftL, shiftR, rotateL, rotateR :: a -> Int -> a
  popCount          :: a -> Int

  bit i             = 1 `shiftL` i
  setBit x i        = x .|. bit i
  clearBit x i      = x .&. complement (bit i)
  complementBit x i = x `xor` bit i
  testBit x i       = (x .&. bit i) /= 0
  shiftL x i        = shift x i
  shiftR x i        = shift x (negate i)
  rotateL x i       = rotate x i
  rotateR x i       = rotate x (negate i)
  shift x i | i >= 0    = x `shiftL` i
            | otherwise = x `shiftR` negate i
  rotate x i | i >= 0    = x `rotateL` i
             | otherwise = x `rotateR` negate i

instance Bits Int where
  (.&.)      = primAndInt
  (.|.)      = primOrInt
  xor        = primXorInt
  complement = primComplementInt
  shift      = primShiftInt
  shiftL     = primShiftInt
  shiftR x i = primShiftInt x (negate i)
  rotate     = primRotateInt
  testBit    = primTestBitInt
  bitSize _  = primIntBits
  isSigned _ = True
  popCount   = primPopCountInt

instance Bits Integer where
  (.&.)      = primAndInteger
  (.|.)      = primOrInteger
  xor        = primXorInteger
  complement = primComplementInteger
  shift      = primShiftInteger
  shiftL     = primShiftInteger
  shiftR x i = primShiftInteger x (negate i)
  rotate     = primShiftInteger
  testBit    = primTestBitInteger
  bitSize _  = error "Data.Bits.bitSize(Integer)"
  isSigned _ = True
  popCount   = primPopCountInteger
