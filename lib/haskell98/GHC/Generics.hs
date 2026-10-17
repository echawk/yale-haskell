{-# LANGUAGE TypeOperators, TypeFamilies, KindSignatures #-}
-- GHC.Generics (base): the classes, with their associated Rep types, and
-- the representation types.  Deriving Generic gives an instance with no
-- Rep and no from or to (derived/derived-instances.mumble): programs and
-- libraries that derive it, or define instances over the representation
-- types (distributive's Distributive U1, ...), compile, but generic
-- programming over a derived instance does not run.
module GHC.Generics (
    Generic(from, to), Rep, Generic1(from1, to1), Rep1,
    V1, U1(U1), Par1(Par1, unPar1), Rec1(Rec1, unRec1), K1(K1, unK1),
    M1(M1, unM1), (:+:)(L1, R1), (:*:)((:*:)), (:.:)(Comp1, unComp1),
    R, D, C, S, Rec0, D1, C1, S1
  ) where

import Prelude hiding (foldr)
import PreludeModern
import Data.Kind (Type)

-- (the fixities of the type operators :+: and :.: are not used here)
infixr 6 :*:

class Generic a where
  type Rep a :: Type -> Type
  from :: a -> Rep a x
  to :: Rep a x -> a

class Generic1 f where
  type Rep1 f :: Type -> Type
  from1 :: f a -> Rep1 f a
  to1 :: Rep1 f a -> f a

data V1 p

data U1 p = U1 deriving (Eq, Ord, Show)

newtype Par1 p = Par1 { unPar1 :: p } deriving (Eq, Ord, Show)

newtype Rec1 f p = Rec1 { unRec1 :: f p }

newtype K1 i c p = K1 { unK1 :: c } deriving (Eq, Ord, Show)

newtype M1 i c f p = M1 { unM1 :: f p }

data (:+:) f g p = L1 (f p) | R1 (g p)

data (:*:) f g p = f p :*: g p

newtype (:.:) f g p = Comp1 { unComp1 :: f (g p) }

data R
data D
data C
data S

type Rec0 = K1 R
type D1 = M1 D
type C1 = M1 C
type S1 = M1 S

instance Functor U1 where
  fmap _ U1 = U1

instance Functor Par1 where
  fmap f (Par1 a) = Par1 (f a)

instance Functor f => Functor (Rec1 f) where
  fmap f (Rec1 a) = Rec1 (fmap f a)

instance Functor (K1 i c) where
  fmap _ (K1 c) = K1 c

instance Functor f => Functor (M1 i c f) where
  fmap f (M1 a) = M1 (fmap f a)

instance (Functor f, Functor g) => Functor (f :+: g) where
  fmap f (L1 a) = L1 (fmap f a)
  fmap f (R1 a) = R1 (fmap f a)

instance (Functor f, Functor g) => Functor (f :*: g) where
  fmap f (a :*: b) = fmap f a :*: fmap f b

instance (Functor f, Functor g) => Functor (f :.: g) where
  fmap f (Comp1 x) = Comp1 (fmap (fmap f) x)

instance Foldable U1 where
  foldMap _ _ = mempty

instance Foldable Par1 where
  foldMap f (Par1 a) = f a

instance Foldable f => Foldable (Rec1 f) where
  foldMap f (Rec1 a) = foldMap f a

instance Foldable f => Foldable (M1 i c f) where
  foldMap f (M1 a) = foldMap f a

instance (Foldable f, Foldable g) => Foldable (f :+: g) where
  foldMap f (L1 a) = foldMap f a
  foldMap f (R1 a) = foldMap f a

instance (Foldable f, Foldable g) => Foldable (f :*: g) where
  foldMap f (a :*: b) = foldMap f a `mappend` foldMap f b

instance (Foldable f, Foldable g) => Foldable (f :.: g) where
  foldMap f (Comp1 x) = foldMap (foldMap f) x
