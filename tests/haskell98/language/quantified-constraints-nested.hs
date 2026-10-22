{-# LANGUAGE QuantifiedConstraints, RankNTypes #-}
module Main where
class Curry a where cshow :: a -> String
instance Curry Int where cshow = show
data L a = N | C a (L a)
instance Curry a => Curry (L a) where
  cshow N = "N"
  cshow (C x r) = cshow x ++ ":" ++ cshow r
newtype T m a = T (m a)
instance (forall x . Curry x => Curry (m x), Curry a) => Curry (T m a) where
  cshow (T v) = "T(" ++ cshow v ++ ")"
lift :: forall t0 . (forall x0 x1 . (forall x2 . Curry x2 => Curry (x0 x2), Curry x1) => Curry (t0 x0 x1))
     => Int -> forall t2 t1 . (forall x0 . Curry x0 => Curry (t2 x0), Curry t1) => t0 t2 t1 -> String
lift n v = show n ++ cshow v
main = putStrLn (lift 3 (T (C (1::Int) N)))
