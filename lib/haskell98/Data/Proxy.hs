-- Data.Proxy (base)
module Data.Proxy (Proxy(Proxy), asProxyTypeOf) where

import Prelude hiding (foldr)
import PreludeModern

data Proxy t = Proxy deriving (Eq, Ord, Show, Read, Bounded)

-- base's instances
instance Functor Proxy where
  fmap _ _ = Proxy
instance Applicative Proxy where
  pure _ = Proxy
  _ <*> _ = Proxy
instance Alternative Proxy where
  empty = Proxy
  _ <|> _ = Proxy
instance Monad Proxy where
  return _ = Proxy
  _ >>= _ = Proxy
instance Foldable Proxy where
  foldMap _ _ = mempty
  foldr _ z _ = z
instance Traversable Proxy where
  traverse _ _ = pure Proxy
instance Semigroup (Proxy s) where
  _ <> _ = Proxy
instance Monoid (Proxy s) where
  mempty = Proxy

instance Enum (Proxy t) where
  fromEnum _ = 0
  toEnum 0 = Proxy
  toEnum _ = error "Proxy.toEnum: 0 expected"

asProxyTypeOf :: a -> proxy a -> a
asProxyTypeOf x _ = x
