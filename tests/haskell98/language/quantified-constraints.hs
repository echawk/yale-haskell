{-# LANGUAGE QuantifiedConstraints, RankNTypes #-}
module Main where
class Curry a where cshow :: a -> String
instance Curry Int where cshow = show
data L a = N | C a (L a)
instance Curry a => Curry (L a) where
  cshow N = "N"
  cshow (C x r) = cshow x ++ ":" ++ cshow r
f :: (forall x . Curry x => Curry (t x)) => t Int -> String
f v = cshow v
g :: (forall x . Curry x => Curry (t x), Curry b) => t b -> t Int -> String
g u v = f v ++ " " ++ cshow u
main = putStrLn (f (C (1::Int) N)) >> putStrLn (g (C (2::Int) N) (C 3 N))
