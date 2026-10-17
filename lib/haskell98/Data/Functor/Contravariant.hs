-- Data.Functor.Contravariant (base): contravariant functors.
module Data.Functor.Contravariant (
    Contravariant(contramap, (>$)), phantom, (>$<), (>$$<), ($<),
    Predicate(Predicate, getPredicate), Comparison(Comparison, getComparison),
    Equivalence(Equivalence, getEquivalence), defaultComparison,
    defaultEquivalence, comparisonEquivalence, Op(Op, getOp)
  ) where

import PreludeModern
import Data.Functor.Const (Const(Const))

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
