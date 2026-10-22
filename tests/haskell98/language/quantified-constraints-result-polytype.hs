{-# LANGUAGE QuantifiedConstraints, RankNTypes #-}
module Main where
class Curry a where cshow :: a -> String
k :: Int -> forall t2 . (forall x0 . Curry x0 => Curry (t2 x0)) => t2 Int -> String
k _ _ = "k"
main = putStrLn "x"
