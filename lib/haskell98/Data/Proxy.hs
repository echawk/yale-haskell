-- Data.Proxy (base)
module Data.Proxy (Proxy(Proxy), asProxyTypeOf) where

data Proxy t = Proxy deriving (Eq, Ord, Show, Read, Bounded)

instance Enum (Proxy t) where
  fromEnum _ = 0
  toEnum 0 = Proxy
  toEnum _ = error "Proxy.toEnum: 0 expected"

asProxyTypeOf :: a -> proxy a -> a
asProxyTypeOf x _ = x
