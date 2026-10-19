-- Termination (--liquid, milestone 6), unsafe: a countdown that can
-- start below zero (line 11), a recursion on a growing list (line 15), a
-- metric that does not decrease (line 20), and an unbounded count up
-- without lazy (line 25).
module Main where

{-@ type Nat = {v:Int | 0 <= v} @-}

{-@ down :: Int -> Int @-}
down :: Int -> Int
down n = if n == 0 then 0 else down (n - 1)

grow :: [Int] -> Int
grow [] = 0
grow xs = grow (0 : xs)

{-@ ack :: m:Nat -> n:Nat -> Nat / [n, m] @-}
ack :: Int -> Int -> Int
ack m n
  | m == 0 = n + 1
  | n == 0 = ack (m - 1) 1
  | otherwise = ack (m - 1) (ack m (n - 1))

forever :: Int -> [Int]
forever n = n : forever (n + 1)

main = print (down 3, grow [], ack 1 1, take 2 (forever 0))
