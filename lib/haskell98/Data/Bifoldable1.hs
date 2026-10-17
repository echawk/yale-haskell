-- Data.Bifoldable1 (base 4.18): non-empty folds over both parameters.
module Data.Bifoldable1 (Bifoldable1(bifold1, bifoldMap1)) where

import PreludeModern
import Data.Bifoldable (Bifoldable)
import Data.Functor.Const (Const(Const))

class Bifoldable t => Bifoldable1 t where
  bifold1    :: Semigroup m => t m m -> m
  bifoldMap1 :: Semigroup m => (a -> m) -> (b -> m) -> t a b -> m

  bifold1 = bifoldMap1 id id

instance Bifoldable1 Either where
  bifoldMap1 f _ (Left a) = f a
  bifoldMap1 _ g (Right b) = g b

instance Bifoldable1 (,) where
  bifoldMap1 f g (a, b) = f a <> g b

instance Bifoldable1 ((,,) x) where
  bifoldMap1 f g (_, a, b) = f a <> g b

instance Bifoldable1 ((,,,) x y) where
  bifoldMap1 f g (_, _, a, b) = f a <> g b

instance Bifoldable1 Const where
  bifoldMap1 f _ (Const a) = f a
