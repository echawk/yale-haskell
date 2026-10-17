-- Data.Functor.Product (base): the product of two functors.
module Data.Functor.Product (Product(Pair)) where

import Prelude hiding (foldr)
import PreludeModern
import Data.Functor.Classes

data Product f g a = Pair (f a) (g a)

instance (Eq1 f, Eq1 g) => Eq1 (Product f g) where
  liftEq eq (Pair x1 y1) (Pair x2 y2) = liftEq eq x1 x2 && liftEq eq y1 y2

instance (Ord1 f, Ord1 g) => Ord1 (Product f g) where
  liftCompare cmp (Pair x1 y1) (Pair x2 y2) = liftCompare cmp x1 x2 <> liftCompare cmp y1 y2

instance (Show1 f, Show1 g) => Show1 (Product f g) where
  liftShowsPrec sp sl d (Pair x y) =
    showsBinaryWith (liftShowsPrec sp sl) (liftShowsPrec sp sl) "Pair" d x y

instance (Eq1 f, Eq1 g, Eq a) => Eq (Product f g a) where
  (==) = eq1

instance (Ord1 f, Ord1 g, Ord a) => Ord (Product f g a) where
  compare = compare1

instance (Show1 f, Show1 g, Show a) => Show (Product f g a) where
  showsPrec = showsPrec1

instance (Functor f, Functor g) => Functor (Product f g) where
  fmap f (Pair x y) = Pair (fmap f x) (fmap f y)

instance (Foldable f, Foldable g) => Foldable (Product f g) where
  foldMap f (Pair x y) = foldMap f x `mappend` foldMap f y

instance (Traversable f, Traversable g) => Traversable (Product f g) where
  traverse f (Pair x y) = liftA2 Pair (traverse f x) (traverse f y)

instance (Applicative f, Applicative g) => Applicative (Product f g) where
  pure x = Pair (pure x) (pure x)
  Pair f g <*> Pair x y = Pair (f <*> x) (g <*> y)

instance (Alternative f, Alternative g) => Alternative (Product f g) where
  empty = Pair empty empty
  Pair x1 y1 <|> Pair x2 y2 = Pair (x1 <|> x2) (y1 <|> y2)

instance (Monad f, Monad g) => Monad (Product f g) where
  return = pure
  Pair m n >>= f = Pair (m >>= fstP . f) (n >>= sndP . f)
    where fstP (Pair a _) = a
          sndP (Pair _ b) = b
