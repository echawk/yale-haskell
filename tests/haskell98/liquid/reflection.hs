-- Reflection (--liquid; doc/plans/LIQUID-HASKELL.md, milestone 8):
-- reflect, inline, and qualif.
module Main where

{-@ type Nat = {v:Int | 0 <= v} @-}

{-@ reflect fib @-}
{-@ fib :: Nat -> Nat @-}
fib :: Int -> Int
fib n = if n <= 1 then n else fib (n - 1) + fib (n - 2)

{-@ fibFive :: {v:Int | v = 5} @-}
fibFive :: Int
fibFive = fib 5

{-@ inline double @-}
double :: Int -> Int
double x = x + x

{-@ quad :: x:Int -> {v:Int | v = double (double x)} @-}
quad :: Int -> Int
quad x = double x + double x

{-@ qualif Twice(v:int, x:int) { v = x + x } @-}

main = print (fibFive, quad 3)
