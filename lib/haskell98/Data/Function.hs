-- Data.Function (base), for Yale Haskell's Haskell 98 dialect.
module Data.Function (id, const, (.), flip, ($), (&), on, fix, applyWhen) where

infixl 0 `on`
infixl 1 &

(&) :: a -> (a -> b) -> b
x & f = f x

on :: (b -> b -> c) -> (a -> b) -> a -> a -> c
on op f x y = f x `op` f y

fix :: (a -> a) -> a
fix f = let x = f x in x

applyWhen :: Bool -> (a -> a) -> a -> a
applyWhen True  f x = f x
applyWhen False _ x = x
