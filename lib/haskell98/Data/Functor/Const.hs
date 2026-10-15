-- Data.Functor.Const (base): the constant functor.
module Data.Functor.Const (Const(Const, getConst)) where

import PreludeModern

newtype Const a b = Const { getConst :: a } deriving (Eq, Ord)

instance Show a => Show (Const a b) where
  showsPrec d (Const x) = showParen (d > 10) (showString "Const " . showsPrec 11 x)

instance Functor (Const m) where
  fmap _ (Const v) = Const v

instance Foldable (Const m) where
  foldr _ z _ = z

instance Traversable (Const m) where
  traverse _ (Const v) = pure (Const v)

instance Monoid m => Applicative (Const m) where
  pure _ = Const mempty
  Const f <*> Const v = Const (f `mappend` v)

instance Semigroup a => Semigroup (Const a b) where
  Const a <> Const b = Const (a <> b)

instance Monoid a => Monoid (Const a b) where
  mempty = Const mempty
