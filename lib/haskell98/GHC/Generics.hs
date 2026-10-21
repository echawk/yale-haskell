{-# LANGUAGE TypeOperators, TypeFamilies, KindSignatures, MagicHash, DataKinds, FlexibleInstances, StandaloneDeriving, DeriveGeneric #-}
-- GHC.Generics (base): the classes, with their associated Rep types, and
-- the representation types.  Deriving Generic and Generic1 gives Rep and
-- from/to as GHC does (derived/generic.mumble), its metadata the promoted
-- Meta types, whose Datatype, Constructor and Selector instances are here.
module GHC.Generics (
    Generic(..), Rep, Generic1(..), Rep1,
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
    Fixity(Prefix, Infix), FixityI(PrefixI, InfixI), Associativity(LeftAssociative,
    RightAssociative, NotAssociative), prec,
    SourceUnpackedness(NoSourceUnpackedness, SourceNoUnpack, SourceUnpack),
    SourceStrictness(NoSourceStrictness, SourceLazy, SourceStrict),
    DecidedStrictness(DecidedLazy, DecidedStrict, DecidedUnpack),
    Generically(Generically), Generically1(Generically1),
    Meta(MetaData, MetaCons, MetaSel)
  ) where

import Prelude hiding (foldr)
import PreludeModern
import Monad (MonadPlus(mzero, mplus))
import Data.Kind (Type)
import GHC.Exts (Addr#, Char#, Double#, Float#, Int#, Word#)
import Data.Proxy (Proxy(Proxy))
import GHC.TypeLits (KnownSymbol, KnownNat, symbolVal, natVal)
import qualified Data.Monoid as Mon
import qualified Data.Semigroup as Semi
import Data.Ord (Down)
import Data.Functor.Identity (Identity)
import Data.Functor.Const (Const)
import qualified Data.Functor.Sum as FSum
import qualified Data.Functor.Product as FProduct
import Data.Functor.Compose (Compose)
import Control.Applicative (ZipList)

-- (the fixities of the type operators :+: and :.: are not used here)
infixr 5 :+:
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
-- base's Monad and MonadPlus instances (4.9)
instance Monad U1 where
  _ >>= _ = U1
instance MonadPlus U1 where
  mzero = U1
  mplus _ _ = U1
instance Monad Par1 where
  Par1 x >>= f = f x
instance Monad f => Monad (Rec1 f) where
  Rec1 x >>= f = Rec1 (x >>= \a -> unRec1 (f a))
instance MonadPlus f => MonadPlus (Rec1 f) where
  mzero = Rec1 mzero
  mplus (Rec1 a) (Rec1 b) = Rec1 (mplus a b)
instance Monad f => Monad (M1 i c f) where
  M1 x >>= f = M1 (x >>= \a -> unM1 (f a))
instance MonadPlus f => MonadPlus (M1 i c f) where
  mzero = M1 mzero
  mplus (M1 a) (M1 b) = M1 (mplus a b)
instance (Monad f, Monad g) => Monad (f :*: g) where
  (m :*: n) >>= f = (m >>= \a -> fstP (f a)) :*: (n >>= \a -> sndP (f a))
    where fstP (a :*: _) = a
          sndP (_ :*: b) = b
instance (MonadPlus f, MonadPlus g) => MonadPlus (f :*: g) where
  mzero = mzero :*: mzero
  mplus (a :*: b) (c :*: d) = mplus a c :*: mplus b d
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

-- Metadata of a datatype, a constructor and a field
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

-- | The metadata of a representation's M1 (base): used as promoted types
-- ('MetaSel 'Nothing u s d) by programs over GHC's representations.
-- Symbol is String here (kinds are not checked).
data Meta = MetaData String String String Bool
          | MetaCons String FixityI Bool
          | MetaSel (Maybe String) SourceUnpackedness SourceStrictness DecidedStrictness

-- The metadata's instances, at the promoted Meta types a derived Rep uses
-- ('MetaData "T" "Module" "main" 'False, ...)
class KnownBoolG b where
  boolValG :: Proxy b -> Bool
instance KnownBoolG 'True where
  boolValG _ = True
instance KnownBoolG 'False where
  boolValG _ = False

class KnownMaybeSymbol m where
  maybeSymbolVal :: Proxy m -> [Char]
instance KnownMaybeSymbol 'Nothing where
  maybeSymbolVal _ = ""
instance KnownSymbol s => KnownMaybeSymbol ('Just s) where
  maybeSymbolVal p = symbolVal (unJustP p)

unJustP :: Proxy ('Just s) -> Proxy s
unJustP _ = Proxy

class KnownAssociativity a where
  associativityVal :: Proxy a -> Associativity
instance KnownAssociativity 'LeftAssociative where
  associativityVal _ = LeftAssociative
instance KnownAssociativity 'RightAssociative where
  associativityVal _ = RightAssociative
instance KnownAssociativity 'NotAssociative where
  associativityVal _ = NotAssociative

class KnownFixityI f where
  fixityVal :: Proxy f -> Fixity
instance KnownFixityI 'PrefixI where
  fixityVal _ = Prefix
instance (KnownAssociativity a, KnownNat n) => KnownFixityI ('InfixI a n) where
  fixityVal p = Infix (associativityVal (infixAssoc p)) (fromInteger (natVal (infixPrec p)))

infixAssoc :: Proxy ('InfixI a n) -> Proxy a
infixAssoc _ = Proxy
infixPrec :: Proxy ('InfixI a n) -> Proxy n
infixPrec _ = Proxy

class KnownUnpackedness u where
  unpackednessVal :: Proxy u -> SourceUnpackedness
instance KnownUnpackedness 'NoSourceUnpackedness where
  unpackednessVal _ = NoSourceUnpackedness
instance KnownUnpackedness 'SourceNoUnpack where
  unpackednessVal _ = SourceNoUnpack
instance KnownUnpackedness 'SourceUnpack where
  unpackednessVal _ = SourceUnpack

class KnownSourceStrictness s where
  sourceStrictnessVal :: Proxy s -> SourceStrictness
instance KnownSourceStrictness 'NoSourceStrictness where
  sourceStrictnessVal _ = NoSourceStrictness
instance KnownSourceStrictness 'SourceLazy where
  sourceStrictnessVal _ = SourceLazy
instance KnownSourceStrictness 'SourceStrict where
  sourceStrictnessVal _ = SourceStrict

class KnownDecidedStrictness d where
  decidedStrictnessVal :: Proxy d -> DecidedStrictness
instance KnownDecidedStrictness 'DecidedLazy where
  decidedStrictnessVal _ = DecidedLazy
instance KnownDecidedStrictness 'DecidedStrict where
  decidedStrictnessVal _ = DecidedStrict
instance KnownDecidedStrictness 'DecidedUnpack where
  decidedStrictnessVal _ = DecidedUnpack

mdName :: t ('MetaData n m p nt) f a -> Proxy n
mdName _ = Proxy
mdModule :: t ('MetaData n m p nt) f a -> Proxy m
mdModule _ = Proxy
mdPackage :: t ('MetaData n m p nt) f a -> Proxy p
mdPackage _ = Proxy
mdNewtype :: t ('MetaData n m p nt) f a -> Proxy nt
mdNewtype _ = Proxy

instance (KnownSymbol n, KnownSymbol m, KnownSymbol p, KnownBoolG nt)
    => Datatype ('MetaData n m p nt) where
  datatypeName x = symbolVal (mdName x)
  moduleName x = symbolVal (mdModule x)
  packageName x = symbolVal (mdPackage x)
  isNewtype x = boolValG (mdNewtype x)

mcName :: t ('MetaCons n f r) g a -> Proxy n
mcName _ = Proxy
mcFixity :: t ('MetaCons n f r) g a -> Proxy f
mcFixity _ = Proxy
mcRecord :: t ('MetaCons n f r) g a -> Proxy r
mcRecord _ = Proxy

instance (KnownSymbol n, KnownFixityI f, KnownBoolG r)
    => Constructor ('MetaCons n f r) where
  conName x = symbolVal (mcName x)
  conFixity x = fixityVal (mcFixity x)
  conIsRecord x = boolValG (mcRecord x)

msName :: t ('MetaSel n u s d) f a -> Proxy n
msName _ = Proxy
msUnpack :: t ('MetaSel n u s d) f a -> Proxy u
msUnpack _ = Proxy
msStrict :: t ('MetaSel n u s d) f a -> Proxy s
msStrict _ = Proxy
msDecided :: t ('MetaSel n u s d) f a -> Proxy d
msDecided _ = Proxy

instance (KnownMaybeSymbol n, KnownUnpackedness u, KnownSourceStrictness s,
          KnownDecidedStrictness d) => Selector ('MetaSel n u s d) where
  selName x = maybeSymbolVal (msName x)
  selSourceUnpackedness x = unpackednessVal (msUnpack x)
  selSourceStrictness x = sourceStrictnessVal (msStrict x)
  selDecidedStrictness x = decidedStrictnessVal (msDecided x)

-- base's instances for its own types
deriving instance Generic [a]
deriving instance Generic1 []
deriving instance Generic (Maybe a)
deriving instance Generic1 Maybe
deriving instance Generic (Either a b)
deriving instance Generic1 (Either a)
deriving instance Generic Bool
deriving instance Generic Ordering
deriving instance Generic ()
deriving instance Generic (a, b)
deriving instance Generic1 ((,) a)
deriving instance Generic (a, b, c)
deriving instance Generic1 ((,,) a b)
deriving instance Generic (a, b, c, d)
deriving instance Generic1 ((,,,) a b c)
deriving instance Generic (a, b, c, d, e)
deriving instance Generic1 ((,,,,) a b c d)
deriving instance Generic (a, b, c, d, e, f)
deriving instance Generic1 ((,,,,,) a b c d e)
deriving instance Generic (a, b, c, d, e, f, g)
deriving instance Generic1 ((,,,,,,) a b c d e f)
deriving instance Generic (NonEmpty a)
deriving instance Generic1 NonEmpty
deriving instance Generic (WrappedMonad m a)
deriving instance Generic1 (WrappedMonad m)
deriving instance Generic (Proxy t)
deriving instance Generic1 Proxy
deriving instance Generic (Down a)
deriving instance Generic1 Down
deriving instance Generic (Identity a)
deriving instance Generic1 Identity
deriving instance Generic (Const a b)
deriving instance Generic1 (Const a)
deriving instance Generic (FSum.Sum f g a)
deriving instance Generic1 (FSum.Sum f g)
deriving instance Generic (FProduct.Product f g a)
deriving instance Generic1 (FProduct.Product f g)
deriving instance Generic (Compose f g a)
deriving instance Functor f => Generic1 (Compose f g)
deriving instance Generic (ZipList a)
deriving instance Generic1 ZipList
deriving instance Generic (Mon.Dual a)
deriving instance Generic1 Mon.Dual
deriving instance Generic (Mon.Endo a)
deriving instance Generic Mon.All
deriving instance Generic Mon.Any
deriving instance Generic (Mon.Sum a)
deriving instance Generic1 Mon.Sum
deriving instance Generic (Mon.Product a)
deriving instance Generic1 Mon.Product
deriving instance Generic (Mon.First a)
deriving instance Generic1 Mon.First
deriving instance Generic (Mon.Last a)
deriving instance Generic1 Mon.Last
deriving instance Generic (Mon.Alt f a)
deriving instance Generic1 (Mon.Alt f)
deriving instance Generic (Mon.Ap f a)
deriving instance Generic1 (Mon.Ap f)
deriving instance Generic (Semi.Min a)
deriving instance Generic1 Semi.Min
deriving instance Generic (Semi.Max a)
deriving instance Generic1 Semi.Max
deriving instance Generic (Semi.First a)
deriving instance Generic1 Semi.First
deriving instance Generic (Semi.Last a)
deriving instance Generic1 Semi.Last
deriving instance Generic (Semi.WrappedMonoid m)
deriving instance Generic1 Semi.WrappedMonoid
deriving instance Generic (Semi.Arg a b)
deriving instance Generic1 (Semi.Arg a)
