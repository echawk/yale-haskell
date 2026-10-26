{-# LANGUAGE DefaultSignatures #-}
-- Data.Bits: the Haskell 2010 library module (Report 2010, chapter 14),
-- for Yale Haskell's Haskell 98 dialect.  Instances for Int (a fixnum:
-- bitSize is 63 on 64-bit SBCL, and shifts wrap at that width) and
-- Integer (no bitSize; shifts are exact).
--
-- GHC's additions (base 4.x) are here too, as methods with defaults, so
-- Haskell 2010 instances still work: bitSizeMaybe, zeroBits,
-- unsafeShiftL/R, the FiniteBits class, bitDefault and friends, and the
-- operators (.<<.), (.>>.), (!<<.), (!>>.), (.^.).  Unlike GHC's, the class
-- keeps the Report's Num superclass.
module Data.Bits (
    Bits((.&.), (.|.), xor, complement, shift, rotate, bit, setBit,
         clearBit, complementBit, testBit, bitSize, isSigned,
         shiftL, shiftR, rotateL, rotateR, popCount,
         bitSizeMaybe, zeroBits, unsafeShiftL, unsafeShiftR),
    FiniteBits(finiteBitSize, countLeadingZeros, countTrailingZeros),
    bitDefault, testBitDefault, popCountDefault, toIntegralSized,
    (.<<.), (.>>.), (!<<.), (!>>.), (.^.), oneBits
  ) where

import BitsPrims

infixl 8 `shift`, `rotate`, `shiftL`, `shiftR`, `rotateL`, `rotateR`
infixl 7 .&.
infixl 6 `xor`
infixl 5 .|.
infixl 8 .<<., .>>., !<<., !>>.
infixl 6 .^.

-- (Eq, as base's: Bits Bool; a type's Num gives the defaults of bit and
-- testBit)
class Eq a => Bits a where
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
  bitSizeMaybe      :: a -> Maybe Int
  zeroBits          :: a
  unsafeShiftL, unsafeShiftR :: a -> Int -> a
  bitSizeMaybe x    = Just (bitSize x)
  zeroBits          = clearBit (bit 0) 0
  unsafeShiftL      = shiftL
  unsafeShiftR      = shiftR

  default bit :: Num a => Int -> a
  bit i             = 1 `shiftL` i
  setBit x i        = x .|. bit i
  clearBit x i      = x .&. complement (bit i)
  complementBit x i = x `xor` bit i
  default testBit :: Num a => a -> Int -> Bool
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
  bitSizeMaybe _ = Nothing
  isSigned _ = True
  popCount   = primPopCountInteger

class Bits b => FiniteBits b where
  finiteBitSize :: b -> Int
  countLeadingZeros, countTrailingZeros :: b -> Int
  countLeadingZeros x = go (finiteBitSize x - 1)
    where go i | i < 0 = finiteBitSize x
               | testBit x i = finiteBitSize x - 1 - i
               | otherwise = go (i - 1)
  countTrailingZeros x = go 0
    where go i | i >= finiteBitSize x = i
               | testBit x i = i
               | otherwise = go (i + 1)

instance FiniteBits Int where
  finiteBitSize = bitSize

instance Bits Bool where
  (.&.)        = (&&)
  (.|.)        = (||)
  xor          = (/=)
  complement   = not
  shift x 0    = x
  shift _ _    = False
  rotate x _   = x
  bit 0        = True
  bit _        = False
  testBit x 0  = x
  testBit _ _  = False
  bitSize _    = 1
  bitSizeMaybe _ = Just 1
  isSigned _   = False
  popCount False = 0
  popCount True  = 1
  zeroBits     = False

instance FiniteBits Bool where
  finiteBitSize _ = 1
  countTrailingZeros x = if x then 0 else 1
  countLeadingZeros x = if x then 0 else 1

bitDefault :: (Bits a, Num a) => Int -> a
bitDefault i = 1 `shiftL` i

testBitDefault :: (Bits a, Num a) => a -> Int -> Bool
testBitDefault x i = (x .&. bit i) /= 0

popCountDefault :: (Bits a, Num a) => a -> Int
popCountDefault = go 0
  where go c 0 = c
        go c w = c `seq` go (c + 1) (w .&. (w - 1))

toIntegralSized :: (Integral a, Integral b, Bounded b) => a -> Maybe b
toIntegralSized x
  | toInteger x >= toInteger (minBound `asTypeOf` y)
    && toInteger x <= toInteger (maxBound `asTypeOf` y) = Just y
  | otherwise = Nothing
  where y = fromIntegral x

(.<<.), (.>>.), (!<<.), (!>>.) :: Bits a => a -> Int -> a
(.<<.) = shiftL
(.>>.) = shiftR
(!<<.) = unsafeShiftL
(!>>.) = unsafeShiftR

(.^.) :: Bits a => a -> a -> a
(.^.) = xor

oneBits :: Bits a => a
oneBits = complement zeroBits
