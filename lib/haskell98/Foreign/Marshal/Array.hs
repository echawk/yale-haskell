-- Foreign.Marshal.Array: the Haskell 2010 library module (Report 2010,
-- chapter 34), for Yale Haskell's Haskell 98 dialect.
module Foreign.Marshal.Array (
    mallocArray, mallocArray0, allocaArray, allocaArray0,
    reallocArray, reallocArray0, callocArray, callocArray0,
    peekArray, peekArray0, pokeArray, pokeArray0,
    newArray, newArray0, withArray, withArray0, withArrayLen, withArrayLen0,
    copyArray, moveArray, lengthArray0, advancePtr
  ) where

import Foreign.Ptr
import Foreign.Storable
import Foreign.Marshal.Alloc
import Foreign.Marshal.Utils

-- the element type of a pointer, for sizeOf
elementOf :: Ptr a -> a
elementOf _ = undefined

mallocArray :: Storable a => Int -> IO (Ptr a)
mallocArray = doMalloc undefined
  where doMalloc :: Storable a' => a' -> Int -> IO (Ptr a')
        doMalloc dummy size = mallocBytes (size * sizeOf dummy)

mallocArray0 :: Storable a => Int -> IO (Ptr a)
mallocArray0 size = mallocArray (size + 1)

callocArray :: Storable a => Int -> IO (Ptr a)
callocArray = doCalloc undefined
  where doCalloc :: Storable a' => a' -> Int -> IO (Ptr a')
        doCalloc dummy size = callocBytes (size * sizeOf dummy)

callocArray0 :: Storable a => Int -> IO (Ptr a)
callocArray0 size = callocArray (size + 1)

allocaArray :: Storable a => Int -> (Ptr a -> IO b) -> IO b
allocaArray = doAlloca undefined
  where doAlloca :: Storable a' => a' -> Int -> (Ptr a' -> IO b') -> IO b'
        doAlloca dummy size = allocaBytes (size * sizeOf dummy)

allocaArray0 :: Storable a => Int -> (Ptr a -> IO b) -> IO b
allocaArray0 size = allocaArray (size + 1)

reallocArray :: Storable a => Ptr a -> Int -> IO (Ptr a)
reallocArray ptr size = reallocBytes ptr (size * sizeOf (elementOf ptr))

reallocArray0 :: Storable a => Ptr a -> Int -> IO (Ptr a)
reallocArray0 ptr size = reallocArray ptr (size + 1)

peekArray :: Storable a => Int -> Ptr a -> IO [a]
peekArray size ptr | size <= 0 = return []
                   | otherwise = f (size - 1) []
  where f 0 acc = peekElemOff ptr 0 >>= \e -> return (e : acc)
        f n acc = peekElemOff ptr n >>= \e -> f (n - 1) (e : acc)

peekArray0 :: (Storable a, Eq a) => a -> Ptr a -> IO [a]
peekArray0 marker ptr = lengthArray0 marker ptr >>= \size -> peekArray size ptr

pokeArray :: Storable a => Ptr a -> [a] -> IO ()
pokeArray ptr vals = sequence_ (zipWith (pokeElemOff ptr) [0 ..] vals)

pokeArray0 :: Storable a => a -> Ptr a -> [a] -> IO ()
pokeArray0 marker ptr vals = pokeArray ptr vals >> pokeElemOff ptr (length vals) marker

newArray :: Storable a => [a] -> IO (Ptr a)
newArray vals = mallocArray (length vals) >>= \ptr -> pokeArray ptr vals >> return ptr

newArray0 :: Storable a => a -> [a] -> IO (Ptr a)
newArray0 marker vals =
  mallocArray0 (length vals) >>= \ptr -> pokeArray0 marker ptr vals >> return ptr

withArray :: Storable a => [a] -> (Ptr a -> IO b) -> IO b
withArray vals = withArrayLen vals . const

withArray0 :: Storable a => a -> [a] -> (Ptr a -> IO b) -> IO b
withArray0 marker vals = withArrayLen0 marker vals . const

withArrayLen :: Storable a => [a] -> (Int -> Ptr a -> IO b) -> IO b
withArrayLen vals f =
  allocaArray len (\ptr -> pokeArray ptr vals >> f len ptr)
  where len = length vals

withArrayLen0 :: Storable a => a -> [a] -> (Int -> Ptr a -> IO b) -> IO b
withArrayLen0 marker vals f =
  allocaArray0 len (\ptr -> pokeArray0 marker ptr vals >> f len ptr)
  where len = length vals

copyArray :: Storable a => Ptr a -> Ptr a -> Int -> IO ()
copyArray dst src size = copyBytes dst src (size * sizeOf (elementOf dst))

moveArray :: Storable a => Ptr a -> Ptr a -> Int -> IO ()
moveArray dst src size = moveBytes dst src (size * sizeOf (elementOf dst))

lengthArray0 :: (Storable a, Eq a) => a -> Ptr a -> IO Int
lengthArray0 marker ptr = loop 0
  where loop i = peekElemOff ptr i >>= \val ->
                   if val == marker then return i else loop (i + 1)

advancePtr :: Storable a => Ptr a -> Int -> Ptr a
advancePtr ptr i = ptr `plusPtr` (i * sizeOf (elementOf ptr))
