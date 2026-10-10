-- Data.IORef (base): mutable references in the IO monad.  An IORef is a
-- Lisp cons (BasePrims.hi); there are no threads, so the atomic
-- operations are the plain ones.
module Data.IORef (
    IORef, newIORef, readIORef, writeIORef, modifyIORef, modifyIORef',
    atomicModifyIORef, atomicModifyIORef', atomicWriteIORef
  ) where

import BasePrims

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
atomicModifyIORef ref f = do
  x <- readIORef ref
  let (x', b) = f x
  writeIORef ref x'
  return b

atomicModifyIORef' :: IORef a -> (a -> (a, b)) -> IO b
atomicModifyIORef' ref f = do
  x <- readIORef ref
  case f x of
    (x', b) -> x' `seq` b `seq` (writeIORef ref x' >> return b)

atomicWriteIORef :: IORef a -> a -> IO ()
atomicWriteIORef = writeIORef
