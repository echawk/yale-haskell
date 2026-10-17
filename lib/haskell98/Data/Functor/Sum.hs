-- Data.Functor.Sum (base): the sum of two functors.
module Data.Functor.Sum (Sum(InL, InR)) where

import Prelude hiding (foldr)
import PreludeModern
import Data.Functor.Classes

data Sum f g a = InL (f a) | InR (g a)

instance (Eq1 f, Eq1 g) => Eq1 (Sum f g) where
  liftEq eq (InL x1) (InL x2) = liftEq eq x1 x2
  liftEq eq (InR y1) (InR y2) = liftEq eq y1 y2
  liftEq _ _ _ = False

instance (Ord1 f, Ord1 g) => Ord1 (Sum f g) where
  liftCompare cmp (InL x1) (InL x2) = liftCompare cmp x1 x2
  liftCompare _ (InL _) (InR _) = LT
  liftCompare _ (InR _) (InL _) = GT
  liftCompare cmp (InR y1) (InR y2) = liftCompare cmp y1 y2

instance (Show1 f, Show1 g) => Show1 (Sum f g) where
  liftShowsPrec sp sl d (InL x) = showsUnaryWith (liftShowsPrec sp sl) "InL" d x
  liftShowsPrec sp sl d (InR y) = showsUnaryWith (liftShowsPrec sp sl) "InR" d y

instance (Eq1 f, Eq1 g, Eq a) => Eq (Sum f g a) where
  (==) = eq1

instance (Ord1 f, Ord1 g, Ord a) => Ord (Sum f g a) where
  compare = compare1

instance (Show1 f, Show1 g, Show a) => Show (Sum f g a) where
  showsPrec = showsPrec1

instance (Functor f, Functor g) => Functor (Sum f g) where
  fmap f (InL x) = InL (fmap f x)
  fmap f (InR y) = InR (fmap f y)

instance (Foldable f, Foldable g) => Foldable (Sum f g) where
  foldMap f (InL x) = foldMap f x
  foldMap f (InR y) = foldMap f y

instance (Traversable f, Traversable g) => Traversable (Sum f g) where
  traverse f (InL x) = InL <$> traverse f x
  traverse f (InR y) = InR <$> traverse f y
