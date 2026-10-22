-- Data.Semigroup (base): Semigroup (PreludeModern's, with sconcat and
-- stimes), and the semigroup newtypes.
module Data.Semigroup (
    Semigroup((<>), sconcat, stimes), stimesMonoid, stimesIdempotent,
    stimesIdempotentMonoid, cycle1, mtimesDefault,
    Min(Min, getMin), Max(Max, getMax), First(First, getFirst),
    Last(Last, getLast), WrappedMonoid(WrapMonoid, unwrapMonoid),
    Dual(Dual, getDual), Endo(Endo, appEndo), All(All, getAll),
    Any(Any, getAny), Sum(Sum, getSum), Product(Product, getProduct),
    diff, Arg(Arg), ArgMin, ArgMax, NonEmpty((:|))
  ) where

import PreludeModern
import Data.Monoid (Dual(..), Endo(..), All(..), Any(..), Sum(..), Product(..))


stimesMonoid :: (Integral b, Monoid a) => b -> a -> a
stimesMonoid n x = if n == 0 then mempty else stimes n x

-- x <> x = x: n copies are one (n > 0)
stimesIdempotent :: Integral b => b -> a -> a
stimesIdempotent n x
  | n <= 0 = error "stimesIdempotent: positive multiplier expected"
  | otherwise = x

stimesIdempotentMonoid :: (Integral b, Monoid a) => b -> a -> a
stimesIdempotentMonoid n x = case compare n 0 of
  LT -> error "stimesIdempotentMonoid: negative multiplier"
  EQ -> mempty
  GT -> x

mtimesDefault :: (Integral b, Monoid a) => b -> a -> a
mtimesDefault = stimesMonoid

cycle1 :: Semigroup m => m -> m
cycle1 xs = xs' where xs' = xs <> xs'

diff :: Semigroup m => m -> Endo m
diff = Endo . (<>)

newtype Min a = Min { getMin :: a } deriving (Eq, Ord, Show, Read, Bounded)
newtype Max a = Max { getMax :: a } deriving (Eq, Ord, Show, Read, Bounded)
newtype First a = First { getFirst :: a } deriving (Eq, Ord, Show, Read, Bounded)
newtype Last a = Last { getLast :: a } deriving (Eq, Ord, Show, Read, Bounded)
newtype WrappedMonoid m = WrapMonoid { unwrapMonoid :: m } deriving (Eq, Ord, Show, Read)

instance Ord a => Semigroup (Min a) where
  Min a <> Min b = Min (min a b)
instance (Ord a, Bounded a) => Monoid (Min a) where
  mempty = Min maxBound

instance Ord a => Semigroup (Max a) where
  Max a <> Max b = Max (max a b)
instance (Ord a, Bounded a) => Monoid (Max a) where
  mempty = Max minBound

instance Semigroup (First a) where
  a <> _ = a
instance Semigroup (Last a) where
  _ <> b = b

instance Monoid m => Semigroup (WrappedMonoid m) where
  WrapMonoid a <> WrapMonoid b = WrapMonoid (a `mappend` b)
instance Monoid m => Monoid (WrappedMonoid m) where
  mempty = WrapMonoid mempty

instance Functor Min where fmap f (Min a) = Min (f a)
instance Functor Max where fmap f (Max a) = Max (f a)
instance Functor First where fmap f (First a) = First (f a)
instance Functor Last where fmap f (Last a) = Last (f a)

instance Foldable Min where foldMap f (Min a) = f a
instance Foldable Max where foldMap f (Max a) = f a
instance Foldable First where foldMap f (First a) = f a
instance Foldable Last where foldMap f (Last a) = f a
instance Traversable Min where traverse f (Min a) = Min <$> f a
instance Traversable Max where traverse f (Max a) = Max <$> f a
instance Traversable First where traverse f (First a) = First <$> f a
instance Traversable Last where traverse f (Last a) = Last <$> f a

instance Applicative Min where
  pure = Min
  Min f <*> Min a = Min (f a)
instance Applicative Max where
  pure = Max
  Max f <*> Max a = Max (f a)
instance Applicative First where
  pure = First
  First f <*> First a = First (f a)
instance Applicative Last where
  pure = Last
  Last f <*> Last a = Last (f a)
instance Monad Min where Min a >>= f = f a
instance Monad Max where Max a >>= f = f a
instance Monad First where First a >>= f = f a
instance Monad Last where Last a >>= f = f a

-- Arg a b: compared on a only (for ArgMin, ArgMax)
data Arg a b = Arg a b deriving (Show, Read)
type ArgMin a b = Min (Arg a b)
type ArgMax a b = Max (Arg a b)

instance Eq a => Eq (Arg a b) where
  Arg a _ == Arg b _ = a == b
instance Ord a => Ord (Arg a b) where
  compare (Arg a _) (Arg b _) = compare a b
  min x@(Arg a _) y@(Arg b _) = if a <= b then x else y
  max x@(Arg a _) y@(Arg b _) = if a >= b then x else y

instance Functor (Arg a) where fmap f (Arg x a) = Arg x (f a)
instance Foldable (Arg a) where foldMap f (Arg _ a) = f a
instance Traversable (Arg a) where traverse f (Arg x a) = Arg x <$> f a

-- base's numeric instances
instance Num a => Num (Min a) where
  Min x + Min y = Min (x + y)
  Min x - Min y = Min (x - y)
  Min x * Min y = Min (x * y)
  negate (Min x) = Min (negate x)
  abs (Min x) = Min (abs x)
  signum (Min x) = Min (signum x)
  fromInteger n = Min (fromInteger n)
instance Num a => Num (Max a) where
  Max x + Max y = Max (x + y)
  Max x - Max y = Max (x - y)
  Max x * Max y = Max (x * y)
  negate (Max x) = Max (negate x)
  abs (Max x) = Max (abs x)
  signum (Max x) = Max (signum x)
  fromInteger n = Max (fromInteger n)
