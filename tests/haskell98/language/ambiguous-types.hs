-- AllowAmbiguousTypes for ordinary functions, chosen by type applications.
{-# LANGUAGE AllowAmbiguousTypes, ScopedTypeVariables, TypeApplications #-}
import Data.Proxy
class Sized a where size :: Proxy a -> Int
instance Sized Int where size _ = 8
instance Sized Bool where size _ = 1
sizeOfType :: forall a. Sized a => Int
sizeOfType = size (Proxy :: Proxy a)
twice :: forall a. Sized a => Int -> Int
twice n = n * sizeOfType @a
main = print (sizeOfType @Int, sizeOfType @Bool, twice @Int 3)
