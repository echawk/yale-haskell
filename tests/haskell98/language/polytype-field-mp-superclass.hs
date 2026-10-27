-- Top's Heuristic: a newtype's polymorphic field, forall m. HasTG m info =>
-- .., whose class has Show info as a superclass: given inside the field's
-- argument (a where-bound function using show), not wanted outside.
{-# LANGUAGE RankNTypes, MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, FlexibleContexts, UndecidableInstances #-}
module Main where

class (Monad m, Show info) => HasTG m info | m -> info where
  getInfo :: m info

newtype Heuristic info = Heuristic (forall m . HasTG m info => info -> m String)

class Two a where two :: a -> Int

describe :: (HasTG m info, Two info) => info -> m String
describe i = do
  j <- getInfo
  return (show i ++ show j ++ show (two i))

avoid :: Two info => Heuristic info
avoid = Heuristic f where
  f i = do
    s <- describe i
    return (s ++ show i)

newtype R a = R (Int -> a)
instance Functor R where fmap f (R g) = R (f . g)
instance Applicative R where pure x = R (const x); R f <*> R x = R (\n -> f n (x n))
instance Monad R where R m >>= k = R (\n -> let R h = k (m n) in h n)
instance HasTG R Int where getInfo = R id
instance Two Int where two = (* 2)

run :: Heuristic Int -> Int -> String
run (Heuristic h) n = let R g = h n in g 7

main = putStrLn (run avoid 3)
