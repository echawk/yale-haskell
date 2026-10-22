{-# LANGUAGE QuantifiedConstraints, RankNTypes #-}
module Main where
import QuantifiedA
g :: (forall x . Curry x => Curry (t x)) => t Int -> String
g v = f v ++ f v
k :: (forall y . Curry y => Curry (t y)) => t Int -> String
k v = h (Apply v)
main = do
  putStrLn (g (C (1::Int) N))
  putStrLn (k (C 5 N))
  putStrLn (cshow (Apply (C (7::Int) N)))
