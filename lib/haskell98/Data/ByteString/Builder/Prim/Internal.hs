-- Data.ByteString.Builder.Prim.Internal (bytestring): a primitive's size
-- or bound, and running it at a pointer.
module Data.ByteString.Builder.Prim.Internal (
    FixedPrim, BoundedPrim, size, sizeBound, runF, runB,
    fixedPrim, boundedPrim, boudedPrim, toB, liftFixedToBounded, emptyF, emptyB
  ) where

import Data.ByteString.Builder.Prim
import Data.Word (Word8)
import Foreign.Ptr (Ptr, plusPtr, minusPtr)
import Foreign.Marshal.Alloc (allocaBytes)
import Foreign.Marshal.Array (pokeArray, peekArray)
import System.IO.Unsafe (unsafePerformIO)

size :: FixedPrim a -> Int
size (FixedPrim n _) = n

sizeBound :: BoundedPrim a -> Int
sizeBound (BoundedPrim n _) = n

runF :: FixedPrim a -> a -> Ptr Word8 -> IO ()
runF (FixedPrim _ e) a p = pokeArray p (e a)

runB :: BoundedPrim a -> a -> Ptr Word8 -> IO (Ptr Word8)
runB (BoundedPrim _ e) a p = do
  let ws = e a
  pokeArray p ws
  return (p `plusPtr` length ws)

toB :: FixedPrim a -> BoundedPrim a
toB = liftFixedToBounded

-- A primitive from its poke: run once per value on a scratch buffer.
fixedPrim :: Int -> (a -> Ptr Word8 -> IO ()) -> FixedPrim a
fixedPrim n io = FixedPrim n (\a -> unsafePerformIO (scratch n (\p -> do
  io a p; peekArray n p)))

-- (bytestring's misspelt name for it, deprecated; double-conversion's)
boudedPrim :: Int -> (a -> Ptr Word8 -> IO (Ptr Word8)) -> BoundedPrim a
boudedPrim = boundedPrim

boundedPrim :: Int -> (a -> Ptr Word8 -> IO (Ptr Word8)) -> BoundedPrim a
boundedPrim n io = BoundedPrim n (\a -> unsafePerformIO (scratch n (\p -> do
  q <- io a p; peekArray (q `minusPtr` p) p)))

scratch :: Int -> (Ptr Word8 -> IO b) -> IO b
scratch n = allocaBytes (max 1 n)
