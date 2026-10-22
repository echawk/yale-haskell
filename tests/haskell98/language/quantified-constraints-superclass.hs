{-# LANGUAGE QuantifiedConstraints, RankNTypes #-}
module Main where
class NonDet a where nd :: a -> String
class NonDet a => Curry a where cshow :: a -> String
instance NonDet Int where nd _ = "i"
instance Curry Int where cshow = show
instance NonDet (L a) where nd _ = "l"
data L a = N | C a (L a)
instance Curry a => Curry (L a) where
  cshow N = "N"
  cshow (C x r) = cshow x ++ ":" ++ cshow r
type C_Apply a b = a b
f :: forall t0 t2 . (forall x0 . (Curry x0) => Curry (C_Apply t2 x0), Curry t0) => C_Apply t2 t0 -> String
f v = cshow v ++ nd v
main = putStrLn (f (C (1::Int) N))
