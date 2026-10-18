-- A constraint on GHC.Generics' Rep1 g (an associated family with a result
-- kind) and unification through it (distributive's genericCollect).
{-# LANGUAGE TypeFamilies, FlexibleContexts, TypeOperators #-}
import GHC.Generics
class GD g where
  gcollect :: Functor f => (a -> g b) -> f a -> g (f b)
instance GD Par1 where
  gcollect f x = Par1 (fmap (unPar1 . f) x)
genericCollect :: (Functor f, Generic1 g, GD (Rep1 g)) => (a -> g b) -> f a -> g (f b)
genericCollect f = to1 . gcollect (from1 . f)
main = print 1   -- (derived Generic1 instances are empty here; the definition is what is checked)
