{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
-- Data.ByteString.Internal (bytestring 0.11): a ByteString shown as its
-- bytes in memory, BS fp len.  Here a ByteString is a packed string
-- (Data.ByteString.Rep), so matching BS copies its bytes to new memory
-- and building one copies them back: O(n) each, with the same results.
module Data.ByteString.Internal (
    ByteString(BS), unBS, bsFromString, packChars, c2w, w2c,
    fromForeignPtr, fromForeignPtr0, toForeignPtr, toForeignPtr0,
    create, unsafeCreate, createAndTrim, mallocByteString,
    unsafePackLenBytes, unsafePackLenChars,
    accursedUnutterablePerformIO, inlinePerformIO, unsafeDupablePerformIO,
    nullForeignPtr
  ) where

import Data.ByteString.Rep (ByteString, unBS, bsFromString, packChars, c2w, w2c)
import Data.Word (Word8)
import Foreign.ForeignPtr (ForeignPtr, mallocForeignPtrBytes, withForeignPtr, plusForeignPtr, newForeignPtr_)
import Foreign.Ptr (Ptr, nullPtr)
import Foreign.Marshal.Array (peekArray, pokeArray)
import System.IO.Unsafe (unsafePerformIO, unsafeDupablePerformIO)

pattern BS :: ForeignPtr Word8 -> Int -> ByteString
pattern BS fp len <- (toForeignPtr0 -> (fp, len))
  where BS fp len = fromForeignPtr0 fp len

-- | The bytes in new memory, and their number.
toForeignPtr0 :: ByteString -> (ForeignPtr Word8, Int)
toForeignPtr0 bs = unsafePerformIO $ do
  let ws = map c2w (unBS bs)
      n = length ws
  fp <- mallocForeignPtrBytes (max 1 n)
  withForeignPtr fp (\p -> pokeArray p ws)
  return (fp, n)

toForeignPtr :: ByteString -> (ForeignPtr Word8, Int, Int)
toForeignPtr bs = case toForeignPtr0 bs of (fp, n) -> (fp, 0, n)

-- | A ByteString of the LEN bytes at FP (copied).
fromForeignPtr0 :: ForeignPtr Word8 -> Int -> ByteString
fromForeignPtr0 fp len = unsafePerformIO $
  withForeignPtr fp (\p -> fmap (bsFromString . map w2c) (peekArray len p))

fromForeignPtr :: ForeignPtr Word8 -> Int -> Int -> ByteString
fromForeignPtr fp off len = fromForeignPtr0 (plusForeignPtr fp off) len

mallocByteString :: Int -> IO (ForeignPtr a)
mallocByteString n = mallocForeignPtrBytes (max 1 n)

-- | A ByteString of N bytes written by F.
create :: Int -> (Ptr Word8 -> IO ()) -> IO ByteString
create n f = do
  fp <- mallocByteString n
  withForeignPtr fp f
  return (fromForeignPtr0 fp n)

unsafeCreate :: Int -> (Ptr Word8 -> IO ()) -> ByteString
unsafeCreate n f = unsafePerformIO (create n f)

-- | At most N bytes; F answers how many it wrote.
createAndTrim :: Int -> (Ptr Word8 -> IO Int) -> IO ByteString
createAndTrim n f = do
  fp <- mallocByteString n
  m <- withForeignPtr fp f
  return (fromForeignPtr0 fp m)

unsafePackLenBytes :: Int -> [Word8] -> ByteString
unsafePackLenBytes _ ws = bsFromString (map w2c ws)

unsafePackLenChars :: Int -> [Char] -> ByteString
unsafePackLenChars _ cs = packChars cs

accursedUnutterablePerformIO :: IO a -> a
accursedUnutterablePerformIO = unsafeDupablePerformIO

inlinePerformIO :: IO a -> a
inlinePerformIO = unsafeDupablePerformIO

-- a ForeignPtr to no memory (zlib's empty buffers)
nullForeignPtr :: ForeignPtr Word8
nullForeignPtr = unsafePerformIO (newForeignPtr_ nullPtr)
{-# NOINLINE nullForeignPtr #-}
