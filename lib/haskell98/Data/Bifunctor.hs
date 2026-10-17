-- Data.Bifunctor (base)
module Data.Bifunctor (Bifunctor(bimap, first, second)) where

import Data.Functor.Const (Const(Const))

class Bifunctor p where
  bimap  :: (a -> b) -> (c -> d) -> p a c -> p b d
  first  :: (a -> b) -> p a c -> p b c
  second :: (b -> c) -> p a b -> p a c

  bimap f g x = first f (second g x)
  first f x = bimap f id x
  second g x = bimap id g x

instance Bifunctor (,) where
  bimap f g (a, b) = (f a, g b)

instance Bifunctor ((,,) x) where
  bimap f g (x, a, b) = (x, f a, g b)

instance Bifunctor ((,,,) x y) where
  bimap f g (x, y, a, b) = (x, y, f a, g b)

instance Bifunctor Const where
  bimap f _ (Const a) = Const (f a)

instance Bifunctor Either where
  bimap f _ (Left a)  = Left (f a)
  bimap _ g (Right b) = Right (g b)
