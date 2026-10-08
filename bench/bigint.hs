module Main where

fact :: Integer -> Integer
fact n = product [1 .. n]

fibs :: [Integer]
fibs = 0 : 1 : zipWith (+) fibs (tail fibs)

ciphersum :: Integer -> Int
ciphersum n = sum (map (\c -> fromEnum c - 48) (show n))

main :: IO ()
main = do
  print (ciphersum (fact 12000))
  print (length (show (fibs !! 100000)))
  print (fact 25)
  print (2 ^ 200 `mod` (10 ^ 9 + 7 :: Integer))
