-- Reflection (--liquid, milestone 8), unsafe: fib 5 is not 6 (line 14),
-- and quad is not double (double x) (line 22).
module Main where

{-@ type Nat = {v:Int | 0 <= v} @-}

{-@ reflect fib @-}
{-@ fib :: Nat -> Nat @-}
fib :: Int -> Int
fib n = if n <= 1 then n else fib (n - 1) + fib (n - 2)

{-@ fibFive :: {v:Int | v = 6} @-}
fibFive :: Int
fibFive = fib 5

{-@ inline double @-}
double :: Int -> Int
double x = x + x

{-@ quad :: x:Int -> {v:Int | v = double (double x)} @-}
quad :: Int -> Int
quad x = double x + x

{-@ qualif Twice(v:int, x:int) { v = x + x } @-}

main = print (fibFive, quad 3)
