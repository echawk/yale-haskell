-- Data.Functor.Constant (transformers): the constant functor, which
-- unlike base's Const is Foldable and Traversable over nothing.
module Data.Functor.Constant (Constant(Constant, getConstant)) where

import Prelude hiding (foldr)
import PreludeModern

newtype Constant a b = Constant { getConstant :: a } deriving (Eq, Ord)

instance Show a => Show (Constant a b) where
  showsPrec d (Constant x) = showParen (d > 10) (showString "Constant " . showsPrec 11 x)

instance Functor (Constant a) where
  fmap _ (Constant x) = Constant x

instance Foldable (Constant a) where
  foldMap _ _ = mempty
  foldr _ z _ = z

instance Traversable (Constant a) where
  traverse _ (Constant x) = pure (Constant x)

instance Semigroup a => Semigroup (Constant a b) where
  Constant x <> Constant y = Constant (x <> y)

instance Monoid a => Monoid (Constant a b) where
  mempty = Constant mempty

instance Monoid a => Applicative (Constant a) where
  pure _ = Constant mempty
  Constant x <*> Constant y = Constant (x <> y)
