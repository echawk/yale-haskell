-- Inference (--liquid, milestone 3), unsafe: the accumulator can go
-- negative (line 11) and the index can reach n (line 16).
module Main where

{-@ at :: n:{v:Int | v > 0} -> {i:Int | 0 <= i && i < n} -> Int @-}
at :: Int -> Int -> Int
at n i = i

{-@ sumTo :: Int -> {v:Int | v >= 0} @-}
sumTo :: Int -> Int
sumTo n = go 0 0
  where go acc i = if i > n then acc else go (acc - i) (i + 1)

total :: Int -> Int
total n = loop 0
  where loop i = if i <= n then at n i + loop (i + 1) else 0

main = print (sumTo 10, total 4)
