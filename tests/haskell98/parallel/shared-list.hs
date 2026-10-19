-- Sparks that walk one shared lazy list (eight capabilities,
-- shared-list.args): its cells are evaluated by whichever thread gets
-- there first, the others wait or use the result.
module Main where

import Control.Parallel.Strategies

primes :: [Int]
primes = sieve [2 ..] where sieve (p:xs) = p : sieve [x | x <- xs, x `mod` p /= 0]

main :: IO ()
main = do
  let counts = parMap rseq (\k -> length (takeWhile (< 2000 + k) primes)) [1 .. 64]
  print (sum counts)
  print (parMap rdeepseq (\i -> take 3 (drop i primes)) [0, 50 .. 250])
