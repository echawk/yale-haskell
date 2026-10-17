-- Data.Foldable1 (base 4.18): non-empty foldable structures.
module Data.Foldable1 (
    Foldable1(fold1, foldMap1, foldMap1', toNonEmpty, maximum, minimum,
              head, last, foldrMap1, foldlMap1', foldlMap1, foldrMap1'),
    foldr1, foldr1', foldl1, foldl1', intercalate1, foldrM1, foldlM1,
    foldrMapM1, foldlMapM1, maximumBy, minimumBy
  ) where

import Prelude hiding (foldr1, foldl1, maximum, minimum, head, last)
import qualified Prelude as P
import PreludeModern hiding (foldr1, foldl1, maximum, minimum)
import Data.List.NonEmpty (NonEmpty((:|)))
import Data.Functor.Identity (Identity(Identity))

-- As base: an instance defines foldMap1 or foldrMap1.
class Foldable t => Foldable1 t where
  fold1      :: Semigroup m => t m -> m
  foldMap1   :: Semigroup m => (a -> m) -> t a -> m
  foldMap1'  :: Semigroup m => (a -> m) -> t a -> m
  toNonEmpty :: t a -> NonEmpty a
  maximum    :: Ord a => t a -> a
  minimum    :: Ord a => t a -> a
  head       :: t a -> a
  last       :: t a -> a
  foldrMap1  :: (a -> b) -> (a -> b -> b) -> t a -> b
  foldlMap1' :: (a -> b) -> (b -> a -> b) -> t a -> b
  foldlMap1  :: (a -> b) -> (b -> a -> b) -> t a -> b
  foldrMap1' :: (a -> b) -> (a -> b -> b) -> t a -> b

  fold1 = foldMap1 id
  foldMap1 f = foldrMap1 f (\a m -> f a <> m)
  foldMap1' f = foldlMap1' f (\m a -> m <> f a)
  toNonEmpty = foldrMap1 (:| []) (\a (b :| bs) -> a :| (b : bs))
  maximum = foldlMap1' id max
  minimum = foldlMap1' id min
  head = foldrMap1 id const
  last = foldlMap1 id (\_ a -> a)
  foldrMap1 f g t = case toNonEmpty t of
                      x :| xs -> go x xs
    where go y [] = f y
          go y (z : zs) = g y (go z zs)
  foldlMap1' f g t = case toNonEmpty t of
                       x :| xs -> let z = f x in z `seq` P.foldl (\acc a -> let acc' = g acc a in acc' `seq` acc') z xs
  foldlMap1 f g t = case toNonEmpty t of
                      x :| xs -> P.foldl g (f x) xs
  foldrMap1' f g t = foldrMap1 f g t

instance Foldable1 NonEmpty where
  toNonEmpty ne = ne
  foldMap1 f (x :| xs) = go (f x) xs
    where go y [] = y
          go y (z : zs) = y <> go (f z) zs

instance Foldable1 Identity where
  foldMap1 f (Identity x) = f x
  toNonEmpty (Identity x) = x :| []

instance Foldable1 ((,) a) where
  foldMap1 f (_, x) = f x
  toNonEmpty (_, x) = x :| []

foldr1 :: Foldable1 t => (a -> a -> a) -> t a -> a
foldr1 = foldrMap1 id

foldr1' :: Foldable1 t => (a -> a -> a) -> t a -> a
foldr1' = foldrMap1' id

foldl1 :: Foldable1 t => (a -> a -> a) -> t a -> a
foldl1 = foldlMap1 id

foldl1' :: Foldable1 t => (a -> a -> a) -> t a -> a
foldl1' = foldlMap1' id

intercalate1 :: (Foldable1 t, Semigroup m) => m -> t m -> m
intercalate1 sep = foldr1 (\a b -> a <> sep <> b)

foldrM1 :: (Foldable1 t, Monad m) => (a -> a -> m a) -> t a -> m a
foldrM1 = foldrMapM1 return

foldrMapM1 :: (Foldable1 t, Monad m) => (a -> m b) -> (a -> b -> m b) -> t a -> m b
foldrMapM1 g f t = case toNonEmpty t of
                     x :| xs -> go x xs
  where go y [] = g y
        go y (z : zs) = go z zs >>= f y

foldlM1 :: (Foldable1 t, Monad m) => (a -> a -> m a) -> t a -> m a
foldlM1 = foldlMapM1 return

foldlMapM1 :: (Foldable1 t, Monad m) => (a -> m b) -> (b -> a -> m b) -> t a -> m b
foldlMapM1 g f t = case toNonEmpty t of
                     x :| xs -> g x >>= \z -> go z xs
  where go z [] = return z
        go z (y : ys) = f z y >>= \z' -> go z' ys

maximumBy :: Foldable1 t => (a -> a -> Ordering) -> t a -> a
maximumBy cmp = foldl1' (\x y -> if cmp x y == GT then x else y)

minimumBy :: Foldable1 t => (a -> a -> Ordering) -> t a -> a
minimumBy cmp = foldl1' (\x y -> if cmp x y == GT then y else x)
