-- Int arithmetic wraps around the fixnum range (modulo 2^63; GHC's Int is
-- 64 bits, so its values differ), also when the operands are constants.
import Data.Bits (xor)
f :: Int -> Int -> Int
f h x = (h * 16777619) `xor` x
main = do
  let h = -2578643520546668380 :: Int
  print (h * 16777619)
  print (f h 5)
  print (foldl f h [1, 2, 3])
