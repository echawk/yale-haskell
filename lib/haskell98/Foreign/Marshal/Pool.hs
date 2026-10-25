{-# LANGUAGE ScopedTypeVariables #-}
-- Foreign.Marshal.Pool (base): memory freed all at once, when its pool
-- is (X11's withPool).  A pool is the list of its blocks.
module Foreign.Marshal.Pool (
    Pool, newPool, freePool, withPool,
    pooledMalloc, pooledMallocBytes, pooledRealloc, pooledReallocBytes,
    pooledMallocArray, pooledMallocArray0, pooledReallocArray, pooledReallocArray0,
    pooledNew, pooledNewArray, pooledNewArray0
  ) where

import Control.Exception (bracket)
import Data.IORef
import Foreign.Marshal.Alloc (mallocBytes, reallocBytes, free)
import Foreign.Marshal.Array (pokeArray, pokeArray0)
import Foreign.Ptr (Ptr, castPtr)
import Foreign.Storable (Storable, sizeOf, poke)

newtype Pool = Pool (IORef [Ptr ()])

newPool :: IO Pool
newPool = fmap Pool (newIORef [])

freePool :: Pool -> IO ()
freePool (Pool r) = readIORef r >>= mapM_ free >> writeIORef r []

withPool :: (Pool -> IO b) -> IO b
withPool = bracket newPool freePool

pooledMallocBytes :: Pool -> Int -> IO (Ptr a)
pooledMallocBytes (Pool r) n = do
  p <- mallocBytes n
  modifyIORef r (p :)
  return (castPtr p)

pooledMalloc :: forall a. Storable a => Pool -> IO (Ptr a)
pooledMalloc pool = pooledMallocBytes pool (sizeOf (undefined :: a))

pooledReallocBytes :: Pool -> Ptr a -> Int -> IO (Ptr a)
pooledReallocBytes (Pool r) p n = do
  let old = castPtr p
  q <- reallocBytes old n
  modifyIORef r (\ps -> q : filter (/= old) ps)
  return (castPtr q)

pooledRealloc :: forall a. Storable a => Pool -> Ptr a -> IO (Ptr a)
pooledRealloc pool p = pooledReallocBytes pool p (sizeOf (undefined :: a))

pooledMallocArray :: forall a. Storable a => Pool -> Int -> IO (Ptr a)
pooledMallocArray pool n = pooledMallocBytes pool (n * sizeOf (undefined :: a))

pooledMallocArray0 :: Storable a => Pool -> Int -> IO (Ptr a)
pooledMallocArray0 pool n = pooledMallocArray pool (n + 1)

pooledReallocArray :: forall a. Storable a => Pool -> Ptr a -> Int -> IO (Ptr a)
pooledReallocArray pool p n = pooledReallocBytes pool p (n * sizeOf (undefined :: a))

pooledReallocArray0 :: Storable a => Pool -> Ptr a -> Int -> IO (Ptr a)
pooledReallocArray0 pool p n = pooledReallocArray pool p (n + 1)

pooledNew :: Storable a => Pool -> a -> IO (Ptr a)
pooledNew pool x = do
  p <- pooledMalloc pool
  poke p x
  return p

pooledNewArray :: Storable a => Pool -> [a] -> IO (Ptr a)
pooledNewArray pool xs = do
  p <- pooledMallocArray pool (length xs)
  pokeArray p xs
  return p

pooledNewArray0 :: Storable a => Pool -> a -> [a] -> IO (Ptr a)
pooledNewArray0 pool end xs = do
  p <- pooledMallocArray0 pool (length xs)
  pokeArray0 end p xs
  return p
