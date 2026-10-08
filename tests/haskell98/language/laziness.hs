-- Non-strict semantics: infinite and self-referential lists, unused
-- arguments that are errors, short-circuiting.
module Main where
import Dialogue (stdout, appendChan, done, abort)

primes :: [Int]
primes = sieve [2..] where sieve (p:xs) = p : sieve [x | x <- xs, x `mod` p /= 0]

fibs :: [Integer]
fibs = 0 : 1 : zipWith (+) fibs (tail fibs)

powers :: [Int]
powers = 1 : map (* 2) powers

konst :: a -> b -> a
konst x _ = x

showInts :: [Int] -> String
showInts = unwords . map show

out :: String
out = unlines
  [ showInts (take 10 primes)
  , show (fibs !! 90)
  , showInts (takeWhile (< 100) powers)
  , take 7 (cycle "ab")
  , show (konst 1 (error "unused") :: Int)
  , show (length [error "a", error "b", error "c"])
  , show (False && error "not evaluated", True || error "not evaluated")
  , show (head (filter (> 1000) (map (^ 2) [1..])))
  ]

main = appendChan stdout out abort done
