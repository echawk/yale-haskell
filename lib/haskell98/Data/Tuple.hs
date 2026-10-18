{-# LANGUAGE PatternSynonyms #-}
-- Data.Tuple (base)
module Data.Tuple (fst, snd, curry, uncurry, swap, Solo(MkSolo), pattern Solo, getSolo) where

import Prelude hiding (foldr)
import PreludeModern

swap :: (a, b) -> (b, a)
swap (a, b) = (b, a)

-- the one-tuple (base 4.16), and Solo, a pattern for MkSolo, as in base
data Solo a = MkSolo a deriving (Eq, Ord, Show, Read, Bounded)

pattern Solo :: a -> Solo a
pattern Solo a = MkSolo a

getSolo :: Solo a -> a
getSolo (MkSolo a) = a

instance Functor Solo where
  fmap f (MkSolo a) = MkSolo (f a)
instance Applicative Solo where
  pure = MkSolo
  MkSolo f <*> MkSolo a = MkSolo (f a)
instance Monad Solo where
  return = pure
  MkSolo a >>= k = k a
instance Foldable Solo where
  foldMap f (MkSolo a) = f a
instance Traversable Solo where
  traverse f (MkSolo a) = fmap MkSolo (f a)
instance Semigroup a => Semigroup (Solo a) where
  MkSolo a <> MkSolo b = MkSolo (a <> b)
instance Monoid a => Monoid (Solo a) where
  mempty = MkSolo mempty
