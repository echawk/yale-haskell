-- Polymorphism and higher-order functions (--liquid; doc/plans/
-- LIQUID-HASKELL.md, milestone 5): refined instantiation of foldr's and
-- ident's type variables, lambdas and function names checked against
-- refined function types, zipWith, and Array bounds.
module Main where
import Array

{-@ type Nat = {v:Int | 0 <= v} @-}

{-@ abs' :: Int -> Nat @-}
abs' :: Int -> Int
abs' x = if x < 0 then 0 - x else x

{-@ sumAbs :: [Int] -> Nat @-}
sumAbs :: [Int] -> Int
sumAbs xs = foldr (\x acc -> abs' x + acc) 0 xs

{-@ applyTwice :: (Nat -> Nat) -> Nat -> Nat @-}
applyTwice :: (Int -> Int) -> Int -> Int
applyTwice f x = f (f x)

{-@ incr :: Nat -> Nat @-}
incr :: Int -> Int
incr n = n + 1

{-@ ident :: a -> a @-}
ident :: a -> a
ident x = x

{-@ magnitude :: Int -> Nat @-}
magnitude :: Int -> Int
magnitude n = ident (abs' n)

{-@ addAll :: xs:[Int] -> {ys:[Int] | len ys = len xs} -> {v:[Int] | len v = len xs} @-}
addAll :: [Int] -> [Int] -> [Int]
addAll xs ys = zipWith (+) xs ys

{-@ table :: {v:Array Int Int | alo v = 0 && ahi v = 4} @-}
table :: Array Int Int
table = listArray (0, 4) [10, 20, 30, 40, 50]

{-@ at :: {i:Int | 0 <= i && i <= 4} -> Int @-}
at :: Int -> Int
at i = table ! i

main = print (sumAbs [1,-2,3], applyTwice incr 3, applyTwice (\x -> x * 2) 1,
              magnitude (-4), addAll [1,2] [3,4], map (\x -> x `div` 2) [4,6], at 2)
