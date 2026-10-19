-- ScopedTypeVariables: a class's variables scope over its default methods.
{-# LANGUAGE ScopedTypeVariables #-}
import Data.Proxy
class Sized a where
  size :: Proxy a -> Int
  size _ = width (undefined :: a) * 2
  width :: a -> Int
instance Sized Int where width _ = 4
instance Sized Bool where
  width _ = 1
  size _ = 7
main = print (size (Proxy :: Proxy Int), size (Proxy :: Proxy Bool))
