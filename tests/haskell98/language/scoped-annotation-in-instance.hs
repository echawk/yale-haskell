-- An annotation with an explicit forall that also mentions an instance's
-- scoped variable scopes its own variables over the expression.
{-# LANGUAGE ScopedTypeVariables, RankNTypes #-}
import Data.Coerce
newtype Tagged s b = Tagged { unTagged :: b }
class Functor g => Dist g where
  collect :: Functor f => (a -> g b) -> f a -> g (f b)
instance Functor (Tagged s) where fmap f (Tagged b) = Tagged (f b)
instance Dist (Tagged t) where
  collect = coerce (fmap :: (a -> b) -> f a -> f b)
    :: forall a b f . Functor f => (a -> Tagged t b) -> f a -> Tagged t (f b)
main = print (unTagged (collect (\x -> Tagged (x + 1) :: Tagged () Int) [1, 2 :: Int]))
