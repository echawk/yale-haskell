-- Refined signatures checked with Z3 (--liquid; doc/plans/LIQUID-HASKELL.md,
-- milestone 2): abs, max, a safe division, a non-negative counter.
module Main where

{-@ type Nat = {v:Int | 0 <= v} @-}
{-@ type NonZero = {v:Int | v /= 0} @-}

{-@ abs' :: x:Int -> {v:Nat | v = x || v = 0 - x} @-}
abs' :: Int -> Int
abs' x = if x < 0 then 0 - x else x

{-@ max' :: a:Int -> b:Int -> {v:Int | v >= a && v >= b} @-}
max' :: Int -> Int -> Int
max' a b = if a > b then a else b

{-@ safeDiv :: Int -> NonZero -> Int @-}
safeDiv :: Int -> Int -> Int
safeDiv x y = x `div` y

{-@ average :: Int -> Nat -> Int @-}
average :: Int -> Int -> Int
average total n = if n == 0 then 0 else safeDiv total n

-- a counter that stays non-negative
{-@ tick :: Nat -> Nat @-}
tick :: Int -> Int
tick c = c + 1

{-@ untick :: Nat -> Nat @-}
untick :: Int -> Int
untick c = if c > 0 then c - 1 else 0

main :: IO ()
main = print (abs' (-3), max' 2 5, safeDiv 7 2, average 10 0, untick (tick (tick 0)))
