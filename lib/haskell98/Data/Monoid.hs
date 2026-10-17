-- Data.Monoid (base): the classes are PreludeModern's.
module Data.Monoid (
    Monoid(mempty, mappend, mconcat), (<>),
    Dual(Dual, getDual), Endo(Endo, appEndo), All(All, getAll),
    Any(Any, getAny), Sum(Sum, getSum), Product(Product, getProduct),
    First(First, getFirst), Last(Last, getLast), Alt(Alt, getAlt),
    Ap(Ap, getAp)
  ) where

import PreludeModern

newtype Dual a = Dual { getDual :: a } deriving (Eq, Ord, Show)

instance Semigroup a => Semigroup (Dual a) where
  Dual a <> Dual b = Dual (b <> a)

instance Monoid a => Monoid (Dual a) where
  mempty = Dual mempty

newtype Endo a = Endo { appEndo :: a -> a }

instance Semigroup (Endo a) where
  Endo f <> Endo g = Endo (f . g)

instance Monoid (Endo a) where
  mempty = Endo id

newtype All = All { getAll :: Bool } deriving (Eq, Ord, Show)

instance Semigroup All where
  All a <> All b = All (a && b)

instance Monoid All where
  mempty = All True

newtype Any = Any { getAny :: Bool } deriving (Eq, Ord, Show)

instance Semigroup Any where
  Any a <> Any b = Any (a || b)

instance Monoid Any where
  mempty = Any False

newtype Sum a = Sum { getSum :: a } deriving (Eq, Ord, Show)

instance Num a => Semigroup (Sum a) where
  Sum a <> Sum b = Sum (a + b)

instance Num a => Monoid (Sum a) where
  mempty = Sum 0

instance Functor Sum where
  fmap f (Sum a) = Sum (f a)

newtype Product a = Product { getProduct :: a } deriving (Eq, Ord, Show)

instance Num a => Semigroup (Product a) where
  Product a <> Product b = Product (a * b)

instance Num a => Monoid (Product a) where
  mempty = Product 1

instance Functor Product where
  fmap f (Product a) = Product (f a)

newtype First a = First { getFirst :: Maybe a } deriving (Eq, Ord, Show)

instance Semigroup (First a) where
  First Nothing <> b = b
  a             <> _ = a

instance Monoid (First a) where
  mempty = First Nothing

newtype Last a = Last { getLast :: Maybe a } deriving (Eq, Ord, Show)

instance Semigroup (Last a) where
  a <> Last Nothing = a
  _ <> b            = b

instance Monoid (Last a) where
  mempty = Last Nothing

-- Alternative as a monoid: <|> and empty
newtype Alt f a = Alt { getAlt :: f a }

instance Show (f a) => Show (Alt f a) where
  showsPrec d (Alt x) = showParen (d >= 11) (showString "Alt {getAlt = " . showsPrec 0 x . showChar '}')

instance Alternative f => Semigroup (Alt f a) where
  Alt x <> Alt y = Alt (x <|> y)

instance Alternative f => Monoid (Alt f a) where
  mempty = Alt empty

instance Functor f => Functor (Alt f) where
  fmap f (Alt x) = Alt (fmap f x)

-- an applicative's results combined: liftA2 (<>)
newtype Ap f a = Ap { getAp :: f a }

instance Show (f a) => Show (Ap f a) where
  showsPrec d (Ap x) = showParen (d >= 11) (showString "Ap {getAp = " . showsPrec 0 x . showChar '}')

instance (Applicative f, Semigroup a) => Semigroup (Ap f a) where
  Ap x <> Ap y = Ap (liftA2 (<>) x y)

instance (Applicative f, Monoid a) => Monoid (Ap f a) where
  mempty = Ap (pure mempty)

instance Functor f => Functor (Ap f) where
  fmap f (Ap x) = Ap (fmap f x)
