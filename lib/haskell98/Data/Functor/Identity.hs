-- Data.Functor.Identity (base)
module Data.Functor.Identity (Identity(Identity, runIdentity)) where

import PreludeModern

newtype Identity a = Identity { runIdentity :: a } deriving (Eq, Ord)

instance Show a => Show (Identity a) where
  showsPrec d (Identity x) = showParen (d > 10) (showString "Identity " . showsPrec 11 x)

instance Functor Identity where
  fmap f (Identity x) = Identity (f x)
  {-# fmap :: Inline #-}

instance Applicative Identity where
  pure = Identity
  Identity f <*> Identity x = Identity (f x)
  {-# pure :: Inline #-}
  {-# (<*>) :: Inline #-}

instance Monad Identity where
  return = Identity
  Identity x >>= k = k x
  _ >> k = k
  {-# return :: Inline #-}
  {-# (>>=) :: Inline #-}
  {-# (>>) :: Inline #-}

instance Foldable Identity where
  foldr f z (Identity x) = f x z

instance Traversable Identity where
  traverse f (Identity x) = fmap Identity (f x)
