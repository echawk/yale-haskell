{-# LANGUAGE GADTs, RankNTypes, TypeOperators, PolyKinds #-}
-- Data.Type.Equality (base): propositional equality of types, written
-- from base's interface.  (~) itself is the type checker's (equality
-- constraints, parser/type-parser.mumble), not a name this module
-- exports.
module Data.Type.Equality (
    (:~:)(Refl), (:~~:)(HRefl),
    sym, trans, castWith, gcastWith, apply, inner, outer,
    TestEquality(testEquality)
  ) where

infix 4 :~:, :~~:

-- a :~: b: a proof that a and b are the same type
data a :~: b where
  Refl :: a :~: a

-- the same, heterogeneously kinded in GHC
data a :~~: b where
  HRefl :: a :~~: a

sym :: (a :~: b) -> (b :~: a)
sym Refl = Refl

trans :: (a :~: b) -> (b :~: c) -> (a :~: c)
trans Refl Refl = Refl

castWith :: (a :~: b) -> a -> b
castWith Refl x = x

gcastWith :: (a :~: b) -> ((a ~ b) => r) -> r
gcastWith Refl x = x

apply :: (f :~: g) -> (a :~: b) -> (f a :~: g b)
apply Refl Refl = Refl

inner :: (f a :~: g b) -> (a :~: b)
inner Refl = Refl

outer :: (f a :~: g b) -> (f :~: g)
outer Refl = Refl

instance Eq (a :~: b) where
  _ == _ = True
instance Ord (a :~: b) where
  compare _ _ = EQ
instance Show (a :~: b) where
  showsPrec _ Refl = showString "Refl"
instance Eq (a :~~: b) where
  _ == _ = True
instance Show (a :~~: b) where
  showsPrec _ HRefl = showString "HRefl"

-- types whose values can be compared for their type's equality
class TestEquality f where
  testEquality :: f a -> f b -> Maybe (a :~: b)

instance TestEquality ((:~:) a) where
  testEquality Refl Refl = Just Refl
