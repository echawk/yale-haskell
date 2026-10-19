-- Termination (--liquid; doc/plans/LIQUID-HASKELL.md, milestone 6): the
-- default metrics (an Int parameter, a list's len, n - i for a loop
-- counting up), an explicit lexicographic metric, and lazy.
module Main where

{-@ type Nat = {v:Int | 0 <= v} @-}

{-@ fact :: Nat -> Nat @-}
fact :: Int -> Int
fact n = if n == 0 then 1 else n * fact (n - 1)

count :: [a] -> Int
count [] = 0
count (_:xs) = 1 + count xs

{-@ range :: Int -> Int -> [Int] @-}
range :: Int -> Int -> [Int]
range lo hi = if lo > hi then [] else lo : range (lo + 1) hi

{-@ ack :: m:Nat -> n:Nat -> Nat / [m, n] @-}
ack :: Int -> Int -> Int
ack m n
  | m == 0 = n + 1
  | n == 0 = ack (m - 1) 1
  | otherwise = ack (m - 1) (ack m (n - 1))

{-@ lazy forever @-}
forever :: Int -> [Int]
forever n = n : forever (n + 1)

main = print (fact 5, count "abc", range 1 4, ack 2 2, take 3 (forever 7))
