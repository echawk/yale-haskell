-- Data.Ord (base)
module Data.Ord (
    Ord(compare, (<), (<=), (>), (>=), max, min), Ordering(LT, EQ, GT),
    comparing, Down(Down, getDown), clamp
  ) where

comparing :: Ord a => (b -> a) -> b -> b -> Ordering
comparing f x y = compare (f x) (f y)

-- The reverse order
newtype Down a = Down { getDown :: a } deriving (Eq, Show)

instance Ord a => Ord (Down a) where
  compare (Down x) (Down y) = compare y x

clamp :: Ord a => (a, a) -> a -> a
clamp (low, high) a = min high (max a low)
