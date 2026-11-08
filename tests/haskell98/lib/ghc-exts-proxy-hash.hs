{-# LANGUAGE MagicHash, DataKinds, ScopedTypeVariables, DeriveGeneric #-}
-- GHC.Exts' Proxy#, natVal', Data.Void's Generic, Data.Binary.Get's
-- remaining, Control.Monad.ST without ioToST (random 1.3, bytes)
import GHC.Exts (Proxy#, proxy#)
import GHC.TypeLits (KnownNat, natVal')
import GHC.Generics (from, datatypeName)
import Data.Void (Void)
import Data.Binary.Get (runGet, remaining, getWord8)
import qualified Data.ByteString.Lazy as L
import Control.Monad.ST

ioToST :: Int
ioToST = 7

main :: IO ()
main = do
  print (natVal' (proxy# :: Proxy# 3))
  print (datatypeName (from (undefined :: Void)))
  print (runGet (getWord8 >> remaining) (L.pack [1, 2, 3, 4]))
  print (runST (return ioToST))
