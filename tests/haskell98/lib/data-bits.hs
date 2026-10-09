module Main where
import Data.Bits

main :: IO ()
main = do
  let x = 0xF0F0 :: Int
      y = 0x0FF0 :: Int
  print (x .&. y, x .|. y, x `xor` y, complement x)
  print (x `shiftL` 4, x `shiftR` 4, shift x (-8), bit 10 :: Int)
  print (setBit (0 :: Int) 3, clearBit x 4, complementBit x 0, testBit x 4, testBit x 3)
  print (popCount x, popCount (-1 :: Int) == bitSize (0 :: Int), isSigned x)
  print (rotate (1 :: Int) (-1) == minBound, rotateL x 0 == x, rotate x (bitSize x) == x)
  print ((1 :: Int) `shiftL` 100, (-8 :: Int) `shiftR` 1, (-1 :: Int) `shiftR` 200)
  let n = 2 ^ 70 + 5 :: Integer
  print (n .&. 0xFF, n .|. 2, n `xor` n, complement n, n `shiftR` 68, n `shiftL` 3)
  print (testBit n 70, testBit n 69, popCount n, popCount (-n), bit 65 :: Integer)
  print (foldr xor 0 [1 .. 100 :: Int], 1 .&. 3 .|. 4 `xor` 6 :: Int)
