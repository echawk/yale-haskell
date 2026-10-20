{-# LANGUAGE TypeOperators #-}
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
import Data.Semigroup (Min(Min), Max(Max), First(First), Last(Last))
import Data.Ord (Down(Down))
import qualified Data.Monoid as Mon
import Complex (Complex((:+)))
import GHC.Generics (V1, Par1(Par1), Rec1(Rec1), M1(M1), (:+:)(L1, R1), (:*:)((:*:)), (:.:)(Comp1))
import qualified Data.Functor.Product as FP
import qualified Data.Functor.Sum as FS
import Data.Functor.Compose (Compose(Compose))
import Control.Monad.Trans.Identity (IdentityT(IdentityT))
import Control.Applicative.Backwards (Backwards(Backwards))
import Control.Applicative.Lift (Lift(Pure, Other))
import Data.Functor.Reverse (Reverse(Reverse))

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
  -- by foldMap1, as base (an instance defining only foldMap1 has all)
  foldrMap1 f g t = appFromMaybe (foldMap1 (FromMaybe . h) t) Nothing
    where h a Nothing = f a
          h a (Just b) = g a b
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

-- the semigroups' one-element newtypes (base 4.18)
instance Foldable1 Min where
  foldMap1 f (Min x) = f x
  toNonEmpty (Min x) = x :| []
instance Foldable1 Max where
  foldMap1 f (Max x) = f x
  toNonEmpty (Max x) = x :| []
instance Foldable1 First where
  foldMap1 f (First x) = f x
  toNonEmpty (First x) = x :| []
instance Foldable1 Last where
  foldMap1 f (Last x) = f x
  toNonEmpty (Last x) = x :| []
instance Foldable1 Down where
  foldMap1 f (Down x) = f x
  toNonEmpty (Down x) = x :| []

instance Foldable1 Mon.Dual where
  foldMap1 f (Mon.Dual x) = f x
  toNonEmpty (Mon.Dual x) = x :| []
instance Foldable1 Mon.Sum where
  foldMap1 f (Mon.Sum x) = f x
  toNonEmpty (Mon.Sum x) = x :| []
instance Foldable1 Mon.Product where
  foldMap1 f (Mon.Product x) = f x
  toNonEmpty (Mon.Product x) = x :| []
instance Foldable1 f => Foldable1 (Mon.Alt f) where
  foldMap1 f (Mon.Alt t) = foldMap1 f t
  toNonEmpty (Mon.Alt t) = toNonEmpty t
instance Foldable1 f => Foldable1 (Mon.Ap f) where
  foldMap1 f (Mon.Ap t) = foldMap1 f t
  toNonEmpty (Mon.Ap t) = toNonEmpty t

instance Foldable1 Complex where
  foldMap1 f (x :+ y) = f x <> f y
  toNonEmpty (x :+ y) = x :| [y]

-- the generic representation types (base 4.18)
instance Foldable1 V1 where
  foldMap1 _ v = v `seq` undefined
instance Foldable1 Par1 where
  foldMap1 f (Par1 x) = f x
instance Foldable1 f => Foldable1 (Rec1 f) where
  foldMap1 f (Rec1 x) = foldMap1 f x
instance Foldable1 f => Foldable1 (M1 i c f) where
  foldMap1 f (M1 x) = foldMap1 f x
instance (Foldable1 f, Foldable1 g) => Foldable1 (f :+: g) where
  foldMap1 f (L1 x) = foldMap1 f x
  foldMap1 f (R1 y) = foldMap1 f y
instance (Foldable1 f, Foldable1 g) => Foldable1 (f :*: g) where
  foldMap1 f (x :*: y) = foldMap1 f x <> foldMap1 f y
instance (Foldable1 f, Foldable1 g) => Foldable1 (f :.: g) where
  foldMap1 f (Comp1 x) = foldMap1 (foldMap1 f) x

-- Data.Functor's
instance (Foldable1 f, Foldable1 g) => Foldable1 (FP.Product f g) where
  foldMap1 f (FP.Pair x y) = foldMap1 f x <> foldMap1 f y
instance (Foldable1 f, Foldable1 g) => Foldable1 (FS.Sum f g) where
  foldMap1 f (FS.InL x) = foldMap1 f x
  foldMap1 f (FS.InR y) = foldMap1 f y
instance (Foldable1 f, Foldable1 g) => Foldable1 (Compose f g) where
  foldMap1 f (Compose x) = foldMap1 (foldMap1 f) x

-- transformers' (0.6.1)
instance Foldable1 f => Foldable1 (IdentityT f) where
  foldMap1 f (IdentityT x) = foldMap1 f x
instance Foldable1 f => Foldable1 (Backwards f) where
  foldMap1 f (Backwards x) = foldMap1 f x
instance Foldable1 f => Foldable1 (Lift f) where
  foldMap1 f (Pure x) = f x
  foldMap1 f (Other y) = foldMap1 f y
instance Foldable1 f => Foldable1 (Reverse f) where
  foldMap1 f (Reverse t) = getDual (foldMap1 (Dual . f) t)
    where getDual (Dual x) = x

newtype Dual a = Dual a
instance Semigroup a => Semigroup (Dual a) where
  Dual a <> Dual b = Dual (b <> a)

-- foldrMap1's semigroup: a function from the rest's result, if any
newtype FromMaybe b = FromMaybe (Maybe b -> b)

appFromMaybe :: FromMaybe b -> Maybe b -> b
appFromMaybe (FromMaybe f) = f

instance Semigroup (FromMaybe b) where
  FromMaybe f <> FromMaybe g = FromMaybe (f . Just . g)

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
