{-# LANGUAGE MagicHash, PatternSynonyms, ViewPatterns #-}
-- GHC.IORef (base): an IORef is an STRef RealWorld (GHC.STRef); Yale
-- Haskell's IORef (Data.IORef) is the same cell.
module GHC.IORef (
    IORef(IORef), newIORef, readIORef, writeIORef,
    atomicModifyIORef, atomicModifyIORef', atomicSwapIORef,
    atomicModifyIORef'_, atomicModifyIORef_
  ) where

import GHC.PrimOps (RealWorld)
import Data.IORef (IORef, newIORef, readIORef, writeIORef, atomicModifyIORef,
                   atomicModifyIORef')
import Data.STRef (STRef)
import Unsafe.Coerce (unsafeCoerce)

pattern IORef :: STRef RealWorld a -> IORef a
pattern IORef r <- (unsafeCoerce -> r)
  where IORef r = unsafeCoerce r

-- | The old value, the new one written (atomically)
atomicSwapIORef :: IORef a -> a -> IO a
atomicSwapIORef r new = atomicModifyIORef r (\old -> (new, old))

-- | The old and new values, the function applied atomically
atomicModifyIORef'_ :: IORef a -> (a -> a) -> IO (a, a)
atomicModifyIORef'_ r f = atomicModifyIORef' r (\old -> let new = f old in new `seq` (new, (old, new)))

atomicModifyIORef_ :: IORef a -> (a -> a) -> IO (a, a)
atomicModifyIORef_ r f = atomicModifyIORef r (\old -> let new = f old in (new, (old, new)))
