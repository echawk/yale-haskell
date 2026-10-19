-- Control.Parallel and Control.Parallel.Strategies with one capability
-- (the default): par does nothing.
module Main where

import Control.Parallel
import Control.Parallel.Strategies
import Control.Concurrent (getNumCapabilities)
import GHC.Conc (numCapabilities)

nfib :: Int -> Int
nfib n | n < 2 = 1
       | otherwise = nfib (n - 1) + nfib (n - 2) + 1

pfib :: Int -> Int
pfib n | n < 15 = nfib n
       | otherwise = a `par` (b `pseq` (a + b + 1))
  where a = pfib (n - 1)
        b = pfib (n - 2)

main :: IO ()
main = do
  n <- getNumCapabilities
  print (n, numCapabilities)
  print (pfib 25)
  print (parMap rdeepseq nfib [10 .. 20])
  print (sum (map nfib [1 .. 20] `using` parListChunk 16 rseq))
  print (take 5 (map (* 2) [1 .. 1000 :: Int] `using` parBuffer 10 rseq))
  print ((nfib 18, nfib 19) `using` parTuple2 rseq rseq)
  print (runEval (do a <- rpar (nfib 20)
                     b <- rseq (nfib 19)
                     return (a + b)))
  print (Just [1, 2, 3 :: Int] `using` parTraversable rdeepseq)
  print ((sum $|| rdeepseq) [1 .. 100 :: Int])
  print ((length .|| rseq) (map nfib) [1 .. 50])
  print ([nfib 15, nfib 16] `using` (parList rseq `dot` evalList r0))
