{-# LANGUAGE MagicHash, PatternSynonyms, ViewPatterns #-}
-- GHC.IORef (base): an IORef is an STRef RealWorld (GHC.STRef); Yale
-- Haskell's IORef (Data.IORef) is the same cell.
module GHC.IORef (
    IORef(IORef), newIORef, readIORef, writeIORef,
    atomicModifyIORef, atomicModifyIORef'
  ) where

import GHC.PrimOps (RealWorld)
import Data.IORef (IORef, newIORef, readIORef, writeIORef, atomicModifyIORef,
                   atomicModifyIORef')
import Data.STRef (STRef)
import Unsafe.Coerce (unsafeCoerce)

pattern IORef :: STRef RealWorld a -> IORef a
pattern IORef r <- (unsafeCoerce -> r)
  where IORef r = unsafeCoerce r
