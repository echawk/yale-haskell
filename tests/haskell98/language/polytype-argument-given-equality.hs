-- A polymorphic argument given an equality on an outer variable (lens'
-- conjoined :: ((p ~ (->)) => q (a -> b) r) -> ..): it holds inside the
-- argument, a functional dependency's improvement there included, and
-- p is not bound outside.
{-# LANGUAGE RankNTypes, TypeFamilies, GADTs, FlexibleContexts, FunctionalDependencies, FlexibleInstances #-}
module Main where

class Conj p where
  conjoined :: ((p ~ (->)) => q (a -> b) r) -> q (p a b) r -> q (p a b) r
  idp :: p a a

instance Conj (->) where
  conjoined l _ = l
  idp = id

one :: Conj p => p Int Int -> Int
one x = conjoined (\f -> let y = (idp `asTypeOf` x) in f 1) (\pf -> 0) x

main = print (one (+1), two (Baz [5]) (+1))

class Biz p w | w -> p where
  ins :: w a -> [a]
newtype Baz p a = Baz [a]
instance Biz p (Baz p) where
  ins (Baz xs) = xs

two :: Conj p => Baz p Int -> p Int Int -> Int
two b x = conjoined (\f -> f (head (insArr b))) (\pf -> 0) x
  where insArr :: Biz (->) w => w a -> [a]
        insArr = ins
