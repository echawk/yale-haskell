-- lens' substEq and mapEq: an argument given (s ~ a, t ~ b), whose type
-- (f s) meets the expected (f a) under the equalities; the equalities
-- take no dictionary, so substEq's \r -> r returns the value itself.
{-# LANGUAGE RankNTypes, GADTs, TypeFamilies #-}
module Main where

data Identical a b s t where
  Identical :: Identical a b a b

substEq :: Identical s t a b -> ((s ~ a, t ~ b) => r) -> r
substEq l = case l of
  Identical -> \r -> r

mapEq :: Identical s t a b -> f s -> f a
mapEq l r = substEq l r

main = print (mapEq (Identical :: Identical Int () Int ()) (Just 3))
