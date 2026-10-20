{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
module Main (main) where

pattern Pair2 :: a -> b -> (a, b)
pattern Pair2 x y <- (id -> (x, y))
  where Pair2 x y = (x, y)

f :: (Int, Int) -> Int
f (Pair2 a b) = go 10
  where go n = n + a * b

g :: Int -> (Int, Int) -> Int
g k (Pair2 a b) = h
  where h = k + a + b

main :: IO ()
main = print (f (3, 4), g 1 (2, 5), h (1, 2), h (5, 3))

h :: (Int, Int) -> Int
h p = case p of
  Pair2 a b | a > b -> big
            | otherwise -> small
    where big = a * 100 + b
          small = b * 100 + a
