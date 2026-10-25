-- Equalities in an instance's context (microlens' Each): a ~ b, a ~ c all
-- apply, and a use matches the head as GHC's general one, then equates.
{-# LANGUAGE TypeFamilies, MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, RankNTypes #-}
type Traversal s t a b = forall f. Applicative f => (a -> f b) -> s -> f t
class Each s t a b | s -> a, t -> b, s b -> t, t a -> s where
  each :: Traversal s t a b
instance (a~b, q~r) => Each (a,b) (q,r) a q where
  each f ~(a,b) = (,) <$> f a <*> f b
instance (a~b, a~c, q~r, q~s) => Each (a,b,c) (q,r,s) a q where
  each f ~(a,b,c) = (,,) <$> f a <*> f b <*> f c
main = print (each (\x -> Just (x + 1)) (1, 2, 3 :: Int))
