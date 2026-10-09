-- Foreign.Marshal.Alloc: the Haskell 2010 library module (Report 2010,
-- chapter 33), for Yale Haskell's Haskell 98 dialect.  alloca uses
-- malloc and free (there is no C stack frame to allocate in); the memory
-- is freed when the action ends, also by an IO error.  finalizerFree
-- is missing (no ForeignPtr yet).
module Foreign.Marshal.Alloc (
    alloca, allocaBytes, allocaBytesAligned,
    malloc, mallocBytes, calloc, callocBytes,
    realloc, reallocBytes, free
  ) where

import ForeignPrims
import PreludeIO (catch)
import Foreign.Ptr
import Foreign.Storable

malloc :: Storable a => IO (Ptr a)
malloc = doMalloc undefined
  where doMalloc :: Storable b => b -> IO (Ptr b)
        doMalloc dummy = mallocBytes (sizeOf dummy)

mallocBytes :: Int -> IO (Ptr a)
mallocBytes = primMalloc

calloc :: Storable a => IO (Ptr a)
calloc = doCalloc undefined
  where doCalloc :: Storable b => b -> IO (Ptr b)
        doCalloc dummy = callocBytes (sizeOf dummy)

callocBytes :: Int -> IO (Ptr a)
callocBytes = primCalloc

alloca :: Storable a => (Ptr a -> IO b) -> IO b
alloca = doAlloca undefined
  where doAlloca :: Storable a' => a' -> (Ptr a' -> IO b') -> IO b'
        doAlloca dummy = allocaBytes (sizeOf dummy)

allocaBytes :: Int -> (Ptr a -> IO b) -> IO b
allocaBytes n action = do
  p <- primMalloc n
  r <- action p `catch` (\e -> primFree p >> ioError e)
  primFree p
  return r

allocaBytesAligned :: Int -> Int -> (Ptr a -> IO b) -> IO b
allocaBytesAligned n _ = allocaBytes n   -- malloc aligns for any C type

realloc :: Storable b => Ptr a -> IO (Ptr b)
realloc p = doRealloc undefined p
  where doRealloc :: Storable b' => b' -> Ptr a' -> IO (Ptr b')
        doRealloc dummy q = primRealloc q (sizeOf dummy)

reallocBytes :: Ptr a -> Int -> IO (Ptr a)
reallocBytes p 0 = free p >> return nullPtr
reallocBytes p n = primRealloc p n

free :: Ptr a -> IO ()
free = primFree
