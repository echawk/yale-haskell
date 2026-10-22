-- GHC.Float (base), the part programs use: conversions, and the IEEE
-- bit casts, computed (Double is a Lisp double-float, Float a single).
module GHC.Float (
    castDoubleToWord64, castWord64ToDouble, castFloatToWord32,
    castWord32ToFloat, float2Double, double2Float, int2Double, double2Int,
    int2Float, float2Int, floatToDigits, showFloat, log1p, expm1,
    RealFloat(..), Floating(..)
  ) where

import Data.Word (Word32, Word64)
import Numeric (floatToDigits, showFloat)

float2Double :: Float -> Double
float2Double = realToFrac

double2Float :: Double -> Float
double2Float = realToFrac

int2Double :: Int -> Double
int2Double = fromIntegral

double2Int :: Double -> Int
double2Int = truncate

int2Float :: Int -> Float
int2Float = fromIntegral

float2Int :: Float -> Int
float2Int = truncate

log1p, expm1 :: Floating a => a -> a
log1p x = log (1 + x)
expm1 x = exp x - 1

-- The IEEE bits of a float with M mantissa bits, bias B, W bits in all.
ieeeBits :: RealFloat a => Int -> Int -> a -> Integer
ieeeBits mbits bias d
  | d == 0 = if isNegativeZero d then 2 ^ (w - 1) else 0
  | isNaN d = (2 ^ (ebits + 1) - 1) * 2 ^ (mbits - 1)
  | isInfinite d = (if d > 0 then 0 else 2 ^ ebits) * 2 ^ mbits + (2 ^ ebits - 1) * 2 ^ mbits
  | otherwise =
      let (m, e) = decodeFloat (abs d)
          sign = if d < 0 then 2 ^ (w - 1) else 0
          e' = toInteger e + toInteger mbits + toInteger bias
      in if e' <= 0
           then sign + (m `div` (2 ^ (1 - e')))
           else sign + e' * 2 ^ mbits + (m - 2 ^ mbits)
  where
    ebits = w - 1 - mbits
    w = if mbits == 52 then 64 else 32

ieeeFromBits :: RealFloat a => Int -> Int -> Integer -> a
ieeeFromBits mbits bias n =
  let w = if mbits == 52 then 64 else 32 :: Int
      ebits = w - 1 - mbits
      sign = if n >= 2 ^ (w - 1) then -1 else 1
      e = (n `div` 2 ^ mbits) `mod` 2 ^ ebits
      m = n `mod` 2 ^ mbits
  in if e == 2 ^ ebits - 1
       then (if m == 0 then sign / 0 else 0 / 0)
       else if e == 0
         then sign * encodeFloat m (1 - bias - mbits)
         else sign * encodeFloat (m + 2 ^ mbits) (fromInteger e - bias - mbits)

castDoubleToWord64 :: Double -> Word64
castDoubleToWord64 = fromInteger . ieeeBits 52 1023

castWord64ToDouble :: Word64 -> Double
castWord64ToDouble = ieeeFromBits 52 1023 . toInteger

castFloatToWord32 :: Float -> Word32
castFloatToWord32 = fromInteger . ieeeBits 23 127

castWord32ToFloat :: Word32 -> Float
castWord32ToFloat = ieeeFromBits 23 127 . toInteger
