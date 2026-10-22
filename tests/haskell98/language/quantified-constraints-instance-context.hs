{-# LANGUAGE QuantifiedConstraints, RankNTypes #-}
module Main where
class NonDet a where nd :: a -> String
class NonDet a => Curry a where cshow :: a -> String
instance NonDet Int where nd _ = "i"
instance Curry Int where cshow = show
data L a = N | C a (L a)
instance NonDet (L a) where nd _ = "l"
instance Curry a => Curry (L a) where
  cshow N = "N"
  cshow (C x r) = cshow x ++ ":" ++ cshow r
instance NonDet [a] where nd _ = "list"
instance Curry a => Curry [a] where cshow xs = concatMap cshow xs
type C_Apply a b = a b
g :: Curry a => a -> String
g = cshow
f :: forall t0 t2 . (forall x0 . (Curry x0) => Curry (C_Apply t2 x0), Curry t0) => C_Apply t2 t0 -> String
f v = g [v, v] ++ nd [v]
main = putStrLn (f (C (1::Int) N))
