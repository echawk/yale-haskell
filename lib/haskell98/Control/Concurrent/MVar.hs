-- Control.Concurrent.MVar (base), single-threaded (Control.Concurrent):
-- an MVar is an IORef holding Maybe a value.  An operation that would
-- block, with no other thread to wake it, fails as GHC's does when every
-- thread is blocked.
module Control.Concurrent.MVar (
    MVar, newMVar, newEmptyMVar, takeMVar, putMVar, readMVar, swapMVar,
    tryTakeMVar, tryPutMVar, tryReadMVar, isEmptyMVar, withMVar,
    withMVarMasked, modifyMVar_, modifyMVar, modifyMVarMasked_,
    modifyMVarMasked, mkWeakMVar
  ) where

import Data.IORef
import System.Mem.Weak (Weak, mkWeak)

newtype MVar a = MVar (IORef (Maybe a))

instance Eq (MVar a) where
  MVar a == MVar b = a == b

blocked :: IO a
blocked = ioError (userError "thread blocked indefinitely in an MVar operation")

newMVar :: a -> IO (MVar a)
newMVar x = fmap MVar (newIORef (Just x))

newEmptyMVar :: IO (MVar a)
newEmptyMVar = fmap MVar (newIORef Nothing)

takeMVar :: MVar a -> IO a
takeMVar (MVar r) = do
  v <- readIORef r
  case v of
    Just x -> writeIORef r Nothing >> return x
    Nothing -> blocked

readMVar :: MVar a -> IO a
readMVar (MVar r) = readIORef r >>= maybe blocked return

putMVar :: MVar a -> a -> IO ()
putMVar (MVar r) x = do
  v <- readIORef r
  case v of
    Nothing -> writeIORef r (Just x)
    Just _ -> blocked

swapMVar :: MVar a -> a -> IO a
swapMVar m x = do { old <- takeMVar m; putMVar m x; return old }

tryTakeMVar :: MVar a -> IO (Maybe a)
tryTakeMVar (MVar r) = do { v <- readIORef r; writeIORef r Nothing; return v }

tryReadMVar :: MVar a -> IO (Maybe a)
tryReadMVar (MVar r) = readIORef r

tryPutMVar :: MVar a -> a -> IO Bool
tryPutMVar (MVar r) x = do
  v <- readIORef r
  case v of
    Nothing -> writeIORef r (Just x) >> return True
    Just _ -> return False

isEmptyMVar :: MVar a -> IO Bool
isEmptyMVar (MVar r) = fmap (maybe True (const False)) (readIORef r)

withMVar, withMVarMasked :: MVar a -> (a -> IO b) -> IO b
withMVar m f = do { x <- takeMVar m; y <- f x; putMVar m x; return y }
withMVarMasked = withMVar

modifyMVar_, modifyMVarMasked_ :: MVar a -> (a -> IO a) -> IO ()
modifyMVar_ m f = takeMVar m >>= f >>= putMVar m
modifyMVarMasked_ = modifyMVar_

modifyMVar, modifyMVarMasked :: MVar a -> (a -> IO (a, b)) -> IO b
modifyMVar m f = do { x <- takeMVar m; (x', y) <- f x; putMVar m x'; return y }
modifyMVarMasked = modifyMVar

-- a weak pointer to the MVar (its finalizer runs through finalize,
-- System.Mem.Weak)
mkWeakMVar :: MVar a -> IO () -> IO (Weak (MVar a))
mkWeakMVar m fin = mkWeak m m (Just fin)
