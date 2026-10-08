module Main where

-- Lazy stream program: Hamming numbers merged from infinite lists,
-- plus a wheel-based prime generator with a lazy composite list.
merge :: [Int] -> [Int] -> [Int]
merge xa@(x : xs) ya@(y : ys)
  | x < y = x : merge xs ya
  | x > y = y : merge xa ys
  | otherwise = x : merge xs ys

hamming :: [Int]
hamming = 1 : merge (map (* 2) hamming) (merge (map (* 3) hamming) (map (* 5) hamming))

wheel :: [Int]
wheel = 2 : 4 : 2 : 4 : 6 : 2 : 6 : 4 : 2 : 4 : 6 : 6 : 2 : 6 : 4 : 2 : 6 : 4 : 6 : 8 : 4 : 2 : 4 : 2 : 4 : 8 : 6 : 4 : 6 : 2 : 4 : 6 : 2 : 6 : 6 : 4 : 2 : 4 : 6 : 2 : 6 : 4 : 2 : 4 : 2 : 10 : 2 : 10 : wheel

spin :: [Int] -> Int -> [Int]
spin (x : xs) n = n : spin xs (n + x)

primes :: [Int]
primes = 2 : 3 : 5 : 7 : filter isPrime (spin wheel 11)

isPrime :: Int -> Bool
isPrime n = all (\p -> n `mod` p /= 0) (takeWhile (\p -> p * p <= n) primes)

main :: IO ()
main = do
  print (hamming !! 10000)
  print (primes !! 20000)
