-- Data.Scientific.Utils: the helpers of scientific 0.3.8.0's Utils module
-- (BSD licence: Data/LICENSE.scientific), for Yale Haskell: roundTo as
-- scientific has it; the cached powers of ten are a Data.Array.
module Data.Scientific.Utils (roundTo, i2d, maxExpt, magnitude) where

import Data.Array (Array, listArray, (!))
import Data.Char (intToDigit)

roundTo :: Int -> [Int] -> (Int, [Int])
roundTo d is =
  case f d True is of
    x@(0,_) -> x
    (1,xs)  -> (1, 1:xs)
    _       -> error "roundTo: bad Value"
 where
  base = 10

  b2 = base `quot` 2

  f n _ []     = (0, replicate n 0)
  f 0 e (x:xs) | x == b2 && e && all (== 0) xs = (0, [])   -- Round to even when at exactly half the base
               | otherwise = (if x >= b2 then 1 else 0, [])
  f n _ (i:xs)
     | i' == base = (1,0:ds)
     | otherwise  = (0,i':ds)
      where
       (c,ds) = f (n-1) (even i) xs
       i'     = c + i

i2d :: Int -> Char
i2d = intToDigit

maxExpt :: Int
maxExpt = 324

expts10 :: Array Int Integer
expts10 = listArray (0, maxExpt - 1) (iterate (* 10) 1)

magnitude :: Num a => Int -> a
magnitude e | e < maxExpt = cachedPow10 e
            | otherwise   = cachedPow10 hi * 10 ^ (e - hi)
    where
      cachedPow10 p = fromInteger (expts10 ! p)
      hi = maxExpt - 1
