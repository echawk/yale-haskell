-- sum and product fuse with their producer and keep a strict accumulator
-- (PreludeList); fromIntegral to Double (prim.encode-double's fixnum path
-- and its bignum fallback).
main :: IO ()
main = do
  print (sum [x * x | x <- [1 .. 1000000 :: Int], odd x])
  print (product [1 .. 20 :: Integer], product ([] :: [Int]), sum ([] :: [Double]))
  print (sum (map fromIntegral [1 .. 100 :: Int]) :: Double)
  print (fromIntegral (-7 :: Int) :: Double, fromIntegral (2 ^ 40 :: Int) :: Double)
  print (fromIntegral (2 ^ 70 + 1 :: Integer) :: Double, realToFrac (1.5 :: Double) :: Double)
  print (sum [0.1, 0.2, 0.3 :: Double])
