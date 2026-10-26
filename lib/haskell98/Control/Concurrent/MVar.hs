-- Control.Concurrent.MVar (base): the runtime's MVars
-- (src/base/concurrent-runtime.lisp), which a thread waits on.  A thread
-- that would wait while every thread waits gets
-- BlockedIndefinitelyOnMVar.
module Control.Concurrent.MVar (
    MVar, newMVar, newEmptyMVar, takeMVar, putMVar, readMVar, swapMVar,
    tryTakeMVar, tryPutMVar, tryReadMVar, isEmptyMVar, withMVar,
    withMVarMasked, modifyMVar_, modifyMVar, modifyMVarMasked_,
    modifyMVarMasked, mkWeakMVar
  ) where

import ConcurrentPrims
import BasePrims (Exc, primNewRef, primReadRef)
import Control.Exception (BlockedIndefinitelyOnMVar(..), SomeException(..),
                          toException, mask, mask_, onException)
import System.Mem.Weak (Weak, mkWeak)

newtype MVar a = MVar (MVarObj a)

instance Eq (MVar a) where
  MVar a == MVar b = primMVarEq a b

blocked :: Exc
blocked = case toException BlockedIndefinitelyOnMVar of SomeException e -> e

newMVar :: a -> IO (MVar a)
newMVar x = do { m <- newEmptyMVar; putMVar m x; return m }

newEmptyMVar :: IO (MVar a)
newEmptyMVar = fmap MVar primNewMVar

takeMVar :: MVar a -> IO a
takeMVar (MVar m) = primTakeMVar m blocked

readMVar :: MVar a -> IO a
readMVar (MVar m) = primReadMVar m blocked

putMVar :: MVar a -> a -> IO ()
putMVar (MVar m) x = primPutMVar m x blocked

swapMVar :: MVar a -> a -> IO a
swapMVar m x = mask_ (do { old <- takeMVar m; putMVar m x; return old })

tryTakeMVar :: MVar a -> IO (Maybe a)
tryTakeMVar (MVar m) = do
  r <- primNewRef undefined
  ok <- primTryTakeMVar m r
  if ok then fmap Just (primReadRef r) else return Nothing

tryReadMVar :: MVar a -> IO (Maybe a)
tryReadMVar (MVar m) = do
  r <- primNewRef undefined
  ok <- primTryReadMVar m r
  if ok then fmap Just (primReadRef r) else return Nothing

tryPutMVar :: MVar a -> a -> IO Bool
tryPutMVar (MVar m) x = primTryPutMVar m x

isEmptyMVar :: MVar a -> IO Bool
isEmptyMVar (MVar m) = primIsEmptyMVar m

withMVar, withMVarMasked :: MVar a -> (a -> IO b) -> IO b
withMVar m f = mask $ \restore -> do
  x <- takeMVar m
  y <- restore (f x) `onException` putMVar m x
  putMVar m x
  return y
withMVarMasked m f = mask_ $ do
  x <- takeMVar m
  y <- f x `onException` putMVar m x
  putMVar m x
  return y

modifyMVar_, modifyMVarMasked_ :: MVar a -> (a -> IO a) -> IO ()
modifyMVar_ m f = mask $ \restore -> do
  x <- takeMVar m
  x' <- restore (f x) `onException` putMVar m x
  putMVar m x'
modifyMVarMasked_ m f = mask_ $ do
  x <- takeMVar m
  x' <- f x `onException` putMVar m x
  putMVar m x'

modifyMVar, modifyMVarMasked :: MVar a -> (a -> IO (a, b)) -> IO b
modifyMVar m f = mask $ \restore -> do
  x <- takeMVar m
  (x', y) <- restore (f x) `onException` putMVar m x
  putMVar m x'
  return y
modifyMVarMasked m f = mask_ $ do
  x <- takeMVar m
  (x', y) <- f x `onException` putMVar m x
  putMVar m x'
  return y

-- a weak pointer to the MVar (its finalizer runs through finalize,
-- System.Mem.Weak)
mkWeakMVar :: MVar a -> IO () -> IO (Weak (MVar a))
mkWeakMVar m fin = mkWeak m m (Just fin)
