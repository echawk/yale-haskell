-- Bits and FiniteBits Bool (base's), and a newtype of Bool deriving them
-- (bitvec's Bit); Bits's superclass is Eq.
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
import Data.Bits
import Data.Word
import Data.Int

newtype Bit = Bit Bool deriving (Eq, Show, Bits, FiniteBits)

main = do
  print (Bit True .&. Bit False, Bit True `xor` Bit False, complement (Bit False))
  print (popCount (Bit True), finiteBitSize (Bit False), testBit (Bit True) 0)
  print (bit 5 :: Int, bit 3 :: Word8, testBit (6 :: Int16) 1, popCount (255 :: Word64))
  print (zeroBits :: Bool, countLeadingZeros False)
