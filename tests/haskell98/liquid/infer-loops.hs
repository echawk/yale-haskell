-- Inferred refinements (--liquid; doc/plans/LIQUID-HASKELL.md, milestone 3):
-- the local loops have no specification; a sum's accumulator is inferred
-- to stay >= 0, and an index to stay within 0 .. n-1.
module Main where

{-@ at :: n:{v:Int | v > 0} -> {i:Int | 0 <= i && i < n} -> Int @-}
at :: Int -> Int -> Int
at n i = i

{-@ sumTo :: Int -> {v:Int | v >= 0} @-}
sumTo :: Int -> Int
sumTo n = go 0 0
  where go acc i = if i > n then acc else go (acc + i) (i + 1)

total :: Int -> Int
total n = loop 0
  where loop i = if i < n then at n i + loop (i + 1) else 0

main = print (sumTo 10, total 4)
