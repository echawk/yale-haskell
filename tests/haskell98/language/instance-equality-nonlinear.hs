-- Equality constraints that make an instance head non-linear (microlens).
{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, GADTs, UndecidableInstances #-}
class Each s t a b | s -> a, t -> b, s b -> t, t a -> s where
  each :: Applicative f => (a -> f b) -> s -> f t
instance (a~b, q~r) => Each (a,b) (q,r) a q where
  each f ~(a,b) = (,) <$> f a <*> f b
main = print (each (\x -> Just (x + 1)) (1 :: Int, 2 :: Int))
