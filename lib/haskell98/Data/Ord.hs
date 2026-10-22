-- Data.Ord (base)
module Data.Ord (
    Ord(compare, (<), (<=), (>), (>=), max, min), Ordering(LT, EQ, GT),
    comparing, Down(Down, getDown), clamp
  ) where

import qualified PreludeModern as M

comparing :: Ord a => (b -> a) -> b -> b -> Ordering
comparing f x y = compare (f x) (f y)

-- The reverse order
newtype Down a = Down { getDown :: a } deriving Eq

-- as if getDown were not a field (base 4.15)
instance Show a => Show (Down a) where
  showsPrec d (Down x) = showParen (d >= 11) (showString "Down " . showsPrec 11 x)

instance Ord a => Ord (Down a) where
  compare (Down x) (Down y) = compare y x

clamp :: Ord a => (a, a) -> a -> a
clamp (low, high) a = min high (max a low)

-- base's instances (4.11): Down is the identity functor
instance Functor Down where
  fmap f (Down a) = Down (f a)

instance M.Applicative Down where
  pure = Down
  Down f <*> Down a = Down (f a)

instance Monad Down where
  return = Down
  Down a >>= k = k a

instance M.Foldable Down where
  foldMap f (Down a) = f a
  foldr f z (Down a) = f a z

instance M.Traversable Down where
  traverse f (Down a) = fmap Down (f a)

instance M.Semigroup a => M.Semigroup (Down a) where
  Down a <> Down b = Down (a M.<> b)

instance M.Monoid a => M.Monoid (Down a) where
  mempty = Down M.mempty

-- base's numeric instances
instance Num a => Num (Down a) where
  Down x + Down y = Down (x + y)
  Down x - Down y = Down (x - y)
  Down x * Down y = Down (x * y)
  negate (Down x) = Down (negate x)
  abs (Down x) = Down (abs x)
  signum (Down x) = Down (signum x)
  fromInteger n = Down (fromInteger n)
