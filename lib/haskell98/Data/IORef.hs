-- Data.IORef (base): mutable references in the IO monad.  An IORef is
-- the runtime's cell (BasePrims.hi); atomicModifyIORef swaps the new
-- value in with a compare-and-swap (Control.Concurrent's threads).
module Data.IORef (
    IORef, newIORef, readIORef, writeIORef, modifyIORef, modifyIORef',
    atomicModifyIORef, atomicModifyIORef', atomicWriteIORef, mkWeakIORef
  ) where

import BasePrims
import System.Mem.Weak (Weak, mkWeak)

newtype IORef a = IORef (Ref a)

instance Eq (IORef a) where
  IORef a == IORef b = primRefEq a b

newIORef :: a -> IO (IORef a)
newIORef x = primNewRef x >>= \r -> return (IORef r)

readIORef :: IORef a -> IO a
readIORef (IORef r) = primReadRef r

writeIORef :: IORef a -> a -> IO ()
writeIORef (IORef r) x = primWriteRef r x

modifyIORef :: IORef a -> (a -> a) -> IO ()
modifyIORef ref f = readIORef ref >>= \x -> writeIORef ref (f x)

-- strict: the new value is evaluated before it is stored
modifyIORef' :: IORef a -> (a -> a) -> IO ()
modifyIORef' ref f = readIORef ref >>= \x -> let x' = f x in x' `seq` writeIORef ref x'

atomicModifyIORef :: IORef a -> (a -> (a, b)) -> IO b
atomicModifyIORef (IORef r) f = primAtomicModifyRef r f

-- (as base's: the new value and the result evaluated)
atomicModifyIORef' :: IORef a -> (a -> (a, b)) -> IO b
atomicModifyIORef' ref f = do
  b <- atomicModifyIORef ref (\x -> case f x of v@(x', _) -> x' `seq` v)
  b `seq` return b

atomicWriteIORef :: IORef a -> a -> IO ()
atomicWriteIORef = writeIORef

{-# newIORef :: Inline #-}
{-# readIORef :: Inline #-}
{-# writeIORef :: Inline #-}
{-# modifyIORef :: Inline #-}
{-# modifyIORef' :: Inline #-}
{-# atomicModifyIORef :: Inline #-}
{-# atomicModifyIORef' :: Inline #-}
{-# atomicWriteIORef :: Inline #-}

-- a weak pointer to the reference (its finalizer runs through finalize,
-- System.Mem.Weak)
mkWeakIORef :: IORef a -> IO () -> IO (Weak (IORef a))
mkWeakIORef ref@(IORef r) fin = mkWeak r ref (Just fin)
