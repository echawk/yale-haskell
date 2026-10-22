{-# LANGUAGE QuantifiedConstraints, RankNTypes #-}
module QuantifiedA where
class Curry a where cshow :: a -> String
instance Curry Int where cshow = show
data Apply f a = Apply (f a)
data L a = N | C a (L a)
instance Curry a => Curry (L a) where
  cshow N = "N"
  cshow (C x r) = cshow x ++ ":" ++ cshow r
instance (forall x . Curry x => Curry (f x), Curry a) => Curry (Apply f a) where
  cshow (Apply v) = "<" ++ cshow v ++ ">"
f :: (forall x . Curry x => Curry (t x)) => t Int -> String
f v = cshow v
h :: (forall x . Curry x => Curry (Apply t x)) => Apply t Int -> String
h v = cshow v ++ "!"
