-- Type classes (--liquid; doc/plans/LIQUID-HASKELL.md, milestone 7): a
-- refined class method type, checked for each instance and used at calls
-- through a dictionary and at a known instance.
module Main where

{-@ class Sized s where
      size :: x:s -> {v:Int | v >= 0}
  @-}
class Sized s where
  size :: s -> Int

instance Sized Int where
  size n = if n < 0 then 0 - n else n

instance Sized Bool where
  size b = 1

total :: Sized a => [a] -> Int
total [] = 0
total (x:xs) = size x + total xs

{-@ safeDiv :: Int -> {v:Int | v /= 0} -> Int @-}
safeDiv :: Int -> Int -> Int
safeDiv a b = a `div` b

avg :: Int -> Int
avg n = safeDiv 100 (size n + 1)

main = print (avg (-3), total [True, False])
