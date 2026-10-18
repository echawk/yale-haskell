{-# LANGUAGE EmptyCase, TypeOperators #-}
-- Data.Functor.Contravariant (base): contravariant functors.
module Data.Functor.Contravariant (
    Contravariant(contramap, (>$)), phantom, (>$<), (>$$<), ($<),
    Predicate(Predicate, getPredicate), Comparison(Comparison, getComparison),
    Equivalence(Equivalence, getEquivalence), defaultComparison,
    defaultEquivalence, comparisonEquivalence, Op(Op, getOp)
  ) where

import PreludeModern
import Data.Functor.Const (Const(Const))
import Data.Proxy (Proxy(Proxy))
import Data.Functor.Reverse (Reverse(Reverse))
import Data.Functor.Compose (Compose(Compose))
import Data.Functor.Product (Product(Pair))
import Data.Functor.Sum (Sum(InL, InR))
import Data.Functor.Constant (Constant(Constant))
import Control.Applicative.Backwards (Backwards(Backwards, forwards))
import Data.Monoid (Alt(Alt, getAlt))
import GHC.Generics (V1, U1(U1), K1(K1), Rec1(Rec1), M1(M1), (:*:)((:*:)),
                     (:+:)(L1, R1), (:.:)(Comp1))

infixl 4 >$, >$<, >$$<, $<

class Contravariant f where
  contramap :: (a' -> a) -> f a -> f a'
  (>$) :: b -> f b -> f a

  (>$) = contramap . const

phantom :: (Functor f, Contravariant f) => f a -> f b
phantom x = () >$ fmap (const ()) x

(>$<) :: Contravariant f => (a -> b) -> f b -> f a
(>$<) = contramap

(>$$<) :: Contravariant f => f b -> (a -> b) -> f a
(>$$<) = flip contramap

($<) :: Contravariant f => f b -> b -> f a
($<) = flip (>$)

newtype Predicate a = Predicate { getPredicate :: a -> Bool }

instance Contravariant Predicate where
  contramap f (Predicate p) = Predicate (p . f)

instance Semigroup (Predicate a) where
  Predicate p <> Predicate q = Predicate (\a -> p a && q a)

instance Monoid (Predicate a) where
  mempty = Predicate (const True)

newtype Comparison a = Comparison { getComparison :: a -> a -> Ordering }

instance Contravariant Comparison where
  contramap f (Comparison c) = Comparison (\a b -> c (f a) (f b))

instance Semigroup (Comparison a) where
  Comparison p <> Comparison q = Comparison (\a b -> p a b <> q a b)

instance Monoid (Comparison a) where
  mempty = Comparison (\_ _ -> EQ)

newtype Equivalence a = Equivalence { getEquivalence :: a -> a -> Bool }

instance Contravariant Equivalence where
  contramap f (Equivalence e) = Equivalence (\a b -> e (f a) (f b))

instance Semigroup (Equivalence a) where
  Equivalence p <> Equivalence q = Equivalence (\a b -> p a b && q a b)

instance Monoid (Equivalence a) where
  mempty = Equivalence (\_ _ -> True)

defaultComparison :: Ord a => Comparison a
defaultComparison = Comparison compare

defaultEquivalence :: Eq a => Equivalence a
defaultEquivalence = Equivalence (==)

comparisonEquivalence :: Comparison a -> Equivalence a
comparisonEquivalence (Comparison p) = Equivalence (\a b -> p a b == EQ)

newtype Op a b = Op { getOp :: b -> a }

instance Contravariant (Op a) where
  contramap f (Op g) = Op (g . f)

instance Semigroup a => Semigroup (Op a b) where
  Op p <> Op q = Op (\a -> p a <> q a)

instance Monoid a => Monoid (Op a b) where
  mempty = Op (const mempty)

instance Contravariant (Const a) where
  contramap _ (Const a) = Const a

instance Contravariant Proxy where
  contramap _ _ = Proxy

instance Contravariant f => Contravariant (Reverse f) where
  contramap f (Reverse a) = Reverse (contramap f a)

instance (Functor f, Contravariant g) => Contravariant (Compose f g) where
  contramap f (Compose fga) = Compose (fmap (contramap f) fga)

instance (Contravariant f, Contravariant g) => Contravariant (Product f g) where
  contramap f (Pair a b) = Pair (contramap f a) (contramap f b)

instance (Contravariant f, Contravariant g) => Contravariant (Sum f g) where
  contramap f (InL a) = InL (contramap f a)
  contramap f (InR b) = InR (contramap f b)

instance Contravariant (Constant a) where
  contramap _ (Constant a) = Constant a

instance Contravariant f => Contravariant (Backwards f) where
  contramap f = Backwards . contramap f . forwards

-- base's, for the generic representation types
instance Contravariant V1 where
  contramap _ x = case x of {}
instance Contravariant U1 where
  contramap _ U1 = U1
instance Contravariant (K1 i c) where
  contramap _ (K1 c) = K1 c
instance Contravariant f => Contravariant (Rec1 f) where
  contramap f (Rec1 fp) = Rec1 (contramap f fp)
instance Contravariant f => Contravariant (M1 i c f) where
  contramap f (M1 fp) = M1 (contramap f fp)
instance (Contravariant f, Contravariant g) => Contravariant (f :*: g) where
  contramap f (xs :*: ys) = contramap f xs :*: contramap f ys
instance (Contravariant f, Contravariant g) => Contravariant (f :+: g) where
  contramap f (L1 xs) = L1 (contramap f xs)
  contramap f (R1 ys) = R1 (contramap f ys)
instance (Functor f, Contravariant g) => Contravariant (f :.: g) where
  contramap f (Comp1 fg) = Comp1 (fmap (contramap f) fg)

instance Contravariant f => Contravariant (Alt f) where
  contramap f = Alt . contramap f . getAlt
