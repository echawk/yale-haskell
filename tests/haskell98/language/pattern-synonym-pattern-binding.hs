{-# LANGUAGE PatternSynonyms, ViewPatterns, BangPatterns #-}
module Main (main) where

pattern Halves :: Int -> Int -> Int
pattern Halves a b <- ((\n -> (n `div` 2, n - n `div` 2)) -> (a, b))

f :: Int -> Int
f n = let !(Halves a b) = n in a * 10 + b

g :: Int -> (Int, Int)
g n = (x, y)
  where Halves x y = n + 1

main :: IO ()
main = print (f 7, g 8, let Halves p q = 4 in p + q)
