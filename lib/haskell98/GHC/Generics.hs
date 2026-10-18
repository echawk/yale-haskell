{-# LANGUAGE TypeOperators, TypeFamilies, KindSignatures, MagicHash #-}
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
    R, D, C, S, Rec0, D1, C1, S1,
    URec, UAddr(UAddr, uAddr#), UChar(UChar, uChar#),
    UDouble(UDouble, uDouble#), UFloat(UFloat, uFloat#), UInt(UInt, uInt#),
    UWord(UWord, uWord#),
    Datatype(datatypeName, moduleName, packageName, isNewtype),
    Constructor(conName, conFixity, conIsRecord),
    Selector(selName, selSourceUnpackedness, selSourceStrictness,
             selDecidedStrictness),
    Fixity(Prefix, Infix), FixityI, Associativity(LeftAssociative,
    RightAssociative, NotAssociative), prec,
    SourceUnpackedness(NoSourceUnpackedness, SourceNoUnpack, SourceUnpack),
    SourceStrictness(NoSourceStrictness, SourceLazy, SourceStrict),
    DecidedStrictness(DecidedLazy, DecidedStrict, DecidedUnpack),
    Generically(Generically), Generically1(Generically1)
  ) where

import Prelude hiding (foldr)
import PreludeModern
import Data.Kind (Type)
import GHC.Exts (Addr#, Char#, Double#, Float#, Int#, Word#)

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

instance Functor V1 where
  fmap _ v = case v of {}
instance Foldable V1 where
  foldMap _ _ = mempty
instance Traversable V1 where
  traverse _ v = case v of {}

instance Foldable (K1 i c) where
  foldMap _ _ = mempty
instance Traversable (K1 i c) where
  traverse _ (K1 c) = pure (K1 c)

instance Traversable U1 where
  traverse _ U1 = pure U1
instance Traversable Par1 where
  traverse f (Par1 a) = Par1 <$> f a
instance Traversable f => Traversable (Rec1 f) where
  traverse f (Rec1 a) = Rec1 <$> traverse f a
instance Traversable f => Traversable (M1 i c f) where
  traverse f (M1 a) = M1 <$> traverse f a
instance (Traversable f, Traversable g) => Traversable (f :+: g) where
  traverse f (L1 a) = L1 <$> traverse f a
  traverse f (R1 a) = R1 <$> traverse f a
instance (Traversable f, Traversable g) => Traversable (f :*: g) where
  traverse f (a :*: b) = liftA2 (:*:) (traverse f a) (traverse f b)
instance (Traversable f, Traversable g) => Traversable (f :.: g) where
  traverse f (Comp1 x) = Comp1 <$> traverse (traverse f) x

instance Applicative U1 where
  pure _ = U1
  _ <*> _ = U1
instance Alternative U1 where
  empty = U1
  _ <|> _ = U1
instance Applicative Par1 where
  pure = Par1
  Par1 f <*> Par1 a = Par1 (f a)
instance Applicative f => Applicative (Rec1 f) where
  pure = Rec1 . pure
  Rec1 f <*> Rec1 a = Rec1 (f <*> a)
instance Alternative f => Alternative (Rec1 f) where
  empty = Rec1 empty
  Rec1 a <|> Rec1 b = Rec1 (a <|> b)
instance Applicative f => Applicative (M1 i c f) where
  pure = M1 . pure
  M1 f <*> M1 a = M1 (f <*> a)
instance Alternative f => Alternative (M1 i c f) where
  empty = M1 empty
  M1 a <|> M1 b = M1 (a <|> b)
instance (Applicative f, Applicative g) => Applicative (f :*: g) where
  pure a = pure a :*: pure a
  (f :*: g) <*> (a :*: b) = (f <*> a) :*: (g <*> b)
instance (Alternative f, Alternative g) => Alternative (f :*: g) where
  empty = empty :*: empty
  (a :*: b) <|> (c :*: d) = (a <|> c) :*: (b <|> d)
instance (Applicative f, Applicative g) => Applicative (f :.: g) where
  pure a = Comp1 (pure (pure a))
  Comp1 f <*> Comp1 a = Comp1 (liftA2 (<*>) f a)
instance Monoid c => Applicative (K1 i c) where
  pure _ = K1 mempty
  K1 a <*> K1 b = K1 (a `mappend` b)

-- The representation of unboxed fields (Int#, ...: here the boxed
-- types).  GHC's URec is a data family with an instance per type, UAddr
-- = URec (Ptr ()) and so on; here each is its own type, so that each
-- has its own instances (transformers-compat: GOrd (UAddr p), GOrd
-- (UChar p), ...), and URec a closed family naming them.
data UAddr p = UAddr { uAddr# :: Addr# }
data UChar p = UChar { uChar# :: Char# }
data UDouble p = UDouble { uDouble# :: Double# }
data UFloat p = UFloat { uFloat# :: Float# }
data UInt p = UInt { uInt# :: Int# }
data UWord p = UWord { uWord# :: Word# }

type family URec a :: Type -> Type where
  URec Addr# = UAddr
  URec Char = UChar
  URec Double = UDouble
  URec Float = UFloat
  URec Int = UInt
  URec Word = UWord

-- Metadata of a datatype, a constructor and a field (GHC gives instances
-- for its type-level descriptions; deriving Generic does not make them
-- here)
class Datatype d where
  datatypeName :: t d f a -> [Char]
  moduleName :: t d f a -> [Char]
  packageName :: t d f a -> [Char]
  isNewtype :: t d f a -> Bool
  isNewtype _ = False

class Constructor c where
  conName :: t c f a -> [Char]
  conFixity :: t c f a -> Fixity
  conFixity _ = Prefix
  conIsRecord :: t c f a -> Bool
  conIsRecord _ = False

class Selector s where
  selName :: t s f a -> [Char]
  selSourceUnpackedness :: t s f a -> SourceUnpackedness
  selSourceUnpackedness _ = NoSourceUnpackedness
  selSourceStrictness :: t s f a -> SourceStrictness
  selSourceStrictness _ = NoSourceStrictness
  selDecidedStrictness :: t s f a -> DecidedStrictness
  selDecidedStrictness _ = DecidedLazy

data Fixity = Prefix | Infix Associativity Int
  deriving (Eq, Show, Ord, Read)

-- the type-level fixity GHC's metadata uses
data FixityI = PrefixI | InfixI Associativity Int

data Associativity = LeftAssociative | RightAssociative | NotAssociative
  deriving (Eq, Show, Ord, Read, Enum, Bounded)

-- a constructor's precedence: 10 for a prefix one
prec :: Fixity -> Int
prec Prefix = 10
prec (Infix _ n) = n

data SourceUnpackedness = NoSourceUnpackedness | SourceNoUnpack | SourceUnpack
  deriving (Eq, Show, Ord, Read, Enum, Bounded)

data SourceStrictness = NoSourceStrictness | SourceLazy | SourceStrict
  deriving (Eq, Show, Ord, Read, Enum, Bounded)

data DecidedStrictness = DecidedLazy | DecidedStrict | DecidedUnpack
  deriving (Eq, Show, Ord, Read, Enum, Bounded)

-- DerivingVia's helpers: instances through the generic representation
newtype Generically a = Generically a
newtype Generically1 f a = Generically1 (f a)
