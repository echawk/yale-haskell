module Main where
import Data.Int
import Data.Word
import Data.Bits

main :: IO ()
main = do
  print (maxBound :: Int8, minBound :: Int8, (maxBound :: Int8) + 1, (fromInteger 200 :: Int8))
  print (maxBound :: Int16, (maxBound :: Int32) + 1, (maxBound :: Int64) + 1, minBound :: Int64)
  print (maxBound :: Word8, (0 :: Word8) - 1, (255 :: Word8) + 2, maxBound :: Word16, maxBound :: Word32)
  print (maxBound :: Word64, (0 :: Word64) - 1, maxBound :: Word)
  print (fromIntegral (300 :: Int) :: Word8, fromIntegral (-1 :: Int) :: Word32, fromIntegral (40000 :: Int) :: Int16)
  print (quotRem (-7 :: Int8) 2, divMod (-7 :: Int8) 2)
  print (complement (0 :: Word8), complement (0 :: Int16), (0x81 :: Word8) `rotate` 1, (1 :: Int8) `shiftL` 7)
  print (popCount (-1 :: Int32), popCount (255 :: Word8), testBit (-1 :: Int8) 9, bitSize (0 :: Word16), isSigned (0 :: Word))
  print ([250 ..] :: [Word8], [1, 3 .. 10] :: [Int8], take 3 [10, 8 ..] :: [Word8])
  print (read "123" :: Int16, read "-5" :: Int8, map fromEnum [1 :: Word8, 2], toEnum 65 :: Word8)
  print (sum (map fromIntegral [1 .. 1000 :: Int]) :: Word8, product [1 .. 20] :: Int32, abs (minBound :: Int8))
  print (toInteger (maxBound :: Word64) + 1, realToFrac (3 :: Int16) :: Double)
