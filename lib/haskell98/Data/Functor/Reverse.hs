-- Data.Functor.Reverse (transformers): a Foldable or Traversable with
-- its elements in the opposite order.
module Data.Functor.Reverse (Reverse(Reverse, getReverse)) where

import Prelude hiding (foldr, foldl)
import PreludeModern
import Data.Functor.Classes
import Data.Monoid (Dual(Dual, getDual))

newtype Reverse f a = Reverse { getReverse :: f a }

instance Eq1 f => Eq1 (Reverse f) where
  liftEq eq (Reverse x) (Reverse y) = liftEq eq x y

instance Ord1 f => Ord1 (Reverse f) where
  liftCompare cmp (Reverse x) (Reverse y) = liftCompare cmp x y

instance Show1 f => Show1 (Reverse f) where
  liftShowsPrec sp sl d (Reverse x) = showsUnaryWith (liftShowsPrec sp sl) "Reverse" d x

instance (Eq1 f, Eq a) => Eq (Reverse f a) where
  (==) = eq1

instance (Ord1 f, Ord a) => Ord (Reverse f a) where
  compare = compare1

instance (Show1 f, Show a) => Show (Reverse f a) where
  showsPrec = showsPrec1

instance Functor f => Functor (Reverse f) where
  fmap f (Reverse a) = Reverse (fmap f a)

instance Applicative f => Applicative (Reverse f) where
  pure = Reverse . pure
  Reverse f <*> Reverse a = Reverse (f <*> a)

instance Alternative f => Alternative (Reverse f) where
  empty = Reverse empty
  Reverse x <|> Reverse y = Reverse (x <|> y)

instance Monad m => Monad (Reverse m) where
  return = pure
  m >>= f = Reverse (getReverse m >>= getReverse . f)

instance Foldable f => Foldable (Reverse f) where
  foldMap f (Reverse t) = getDual (foldMap (Dual . f) t)
  foldr f z (Reverse t) = foldl (flip f) z t
  foldl f z (Reverse t) = foldr (flip f) z t

-- the effects happen in the reverse order too (base's uses Backwards)
instance Traversable f => Traversable (Reverse f) where
  traverse f (Reverse t) = fmap Reverse (forwards (traverse (Backwards . f) t))

newtype Backwards f a = Backwards { forwards :: f a }

instance Functor f => Functor (Backwards f) where
  fmap f (Backwards a) = Backwards (fmap f a)

instance Applicative f => Applicative (Backwards f) where
  pure = Backwards . pure
  Backwards f <*> Backwards a = Backwards (liftA2 (\x g -> g x) a f)
