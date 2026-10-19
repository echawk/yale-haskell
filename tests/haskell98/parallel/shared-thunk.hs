-- Sparks that share one thunk (eight capabilities, shared-thunk.args):
-- the threads that find it being evaluated by another wait for it.
module Main where

import Control.Parallel.Strategies

main :: IO ()
main = do
  let shared = sum [1 .. 300000 :: Int]
      xs = parMap rseq (\i -> shared `mod` i + i) [1 .. 64]
  print (sum xs)
  let ys = [length (show shared) + i | i <- [1 .. 32 :: Int]] `using` parList rseq
  print ys
