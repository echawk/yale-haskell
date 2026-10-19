-- Polymorphism and higher-order functions (--liquid, milestone 5), unsafe:
-- a fold that can go negative (line 12), f applied outside its domain
-- (16), ident's result (28), functions that are not Nat -> Nat and a
-- division by an unrefined element (30), an index out of bounds (38).
module Main where
import Array

{-@ type Nat = {v:Int | 0 <= v} @-}

{-@ sumAll :: [Int] -> Nat @-}
sumAll :: [Int] -> Int
sumAll xs = foldr (\x acc -> x + acc) 0 xs

{-@ applyTwice :: (Nat -> Nat) -> Nat -> Nat @-}
applyTwice :: (Int -> Int) -> Int -> Int
applyTwice f x = f (f x - 1)

{-@ decr :: Int -> Int @-}
decr :: Int -> Int
decr n = n - 1

{-@ ident :: a -> a @-}
ident :: a -> a
ident x = x

{-@ neg :: Nat -> Nat @-}
neg :: Int -> Int
neg n = ident (0 - n)

main = print (sumAll [1], applyTwice decr 3, applyTwice (\x -> x - 1) 1, neg 0,
              map (\x -> 10 `div` x) [4,6], outOfBounds 1)

{-@ table :: {v:Array Int Int | alo v = 0 && ahi v = 4} @-}
table :: Array Int Int
table = listArray (0, 4) [10, 20, 30, 40, 50]

outOfBounds :: Int -> Int
outOfBounds i = table ! (i + 5)
