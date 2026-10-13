-- Control.Applicative.Backwards (transformers): an applicative functor
-- whose effects run in the reverse order.
module Control.Applicative.Backwards (Backwards(Backwards, forwards)) where

import Control.Applicative (Alternative(..), liftA2)


newtype Backwards f a = Backwards { forwards :: f a }

instance Functor f => Functor (Backwards f) where
  fmap f (Backwards a) = Backwards (fmap f a)

instance Applicative f => Applicative (Backwards f) where
  pure a = Backwards (pure a)
  Backwards f <*> Backwards a = Backwards (liftA2 (\x g -> g x) a f)

instance Alternative f => Alternative (Backwards f) where
  empty = Backwards empty
  Backwards a <|> Backwards b = Backwards (a <|> b)

instance Foldable f => Foldable (Backwards f) where
  foldr f z (Backwards t) = foldr f z t

instance Traversable f => Traversable (Backwards f) where
  traverse f (Backwards t) = fmap Backwards (traverse f t)
