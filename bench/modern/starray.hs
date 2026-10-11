-- Data.Array.ST: sieve of Eratosthenes on an STUArray of 10^7 Bools,
-- with BangPatterns loops, then a counting pass.
{-# LANGUAGE BangPatterns #-}
import Control.Monad
import Control.Monad.ST
import Data.Array.ST
import Data.Array.Unboxed

sieve :: Int -> UArray Int Bool
sieve n = runSTUArray $ do
  a <- newArray (2, n) True
  let outer !i
        | i * i > n = return ()
        | otherwise = do
            p <- readArray a i
            when p $ let inner !j | j > n = return ()
                                  | otherwise = writeArray a j False >> inner (j + i)
                     in inner (i * i)
            outer (i + 1)
  outer 2
  return a

main :: IO ()
main = do
  let a = sieve 10000000
      count !acc i | i > 10000000 = acc
                   | a ! i = count (acc + 1) (i + 1)
                   | otherwise = count acc (i + 1)
  print (count (0 :: Int) 2)
  print (last [i | i <- [9999900 .. 10000000], a ! i])
