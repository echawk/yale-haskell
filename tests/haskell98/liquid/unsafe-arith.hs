-- Must be rejected: a division by a value that may be zero, and a counter
-- that may go below zero (errors at lines 14 and 18).
module Main where

{-@ type Nat = {v:Int | 0 <= v} @-}
{-@ type NonZero = {v:Int | v /= 0} @-}

{-@ safeDiv :: Int -> NonZero -> Int @-}
safeDiv :: Int -> Int -> Int
safeDiv x y = x `div` y

{-@ average :: Int -> Nat -> Int @-}
average :: Int -> Int -> Int
average total n = safeDiv total n

{-@ untick :: Nat -> Nat @-}
untick :: Int -> Int
untick c = c - 1

main :: IO ()
main = print (average 10 2, untick 3)
