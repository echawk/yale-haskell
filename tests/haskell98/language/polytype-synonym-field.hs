{-# LANGUAGE RankNTypes, TypeOperators, GADTs #-}
-- A constructor field whose type is a polytype synonym of the same
-- module (profunctors: Cotambara :: (r :-> q) -> r a b -> Cotambara q a b).
module Main where

type p :-> q = forall a b. p a b -> q a b

newtype Fn a b = Fn (a -> b)

data Nat2 p q = Nat2 (p :-> q)

data Wrapped q a b where
  Wrapped :: (r :-> q) -> r a b -> Wrapped q a b

apply :: Nat2 p q -> p a b -> q a b
apply (Nat2 f) x = f x

unwrap :: Wrapped q a b -> q a b
unwrap (Wrapped f x) = f x

twice :: Fn :-> Fn
twice (Fn f) = Fn (f . f)

main :: IO ()
main = do
  case apply (Nat2 twice) (Fn (+ 1)) of Fn g -> print (g (40 :: Int))
  case unwrap (Wrapped twice (Fn (* 2))) of Fn g -> print (g (5 :: Int))
