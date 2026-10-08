module Main where

primes :: [Int]
primes = sieve [2 ..]
  where sieve (p : xs) = p : sieve [x | x <- xs, x `mod` p /= 0]

main :: IO ()
main = do
  print (primes !! 2000)
  print (sum (take 1000 primes))
