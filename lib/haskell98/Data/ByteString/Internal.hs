{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
-- Data.ByteString.Internal (bytestring 0.11): a ByteString shown as its
-- bytes in memory, BS fp len.  Here a ByteString is a packed string
-- (Data.ByteString.Rep), so matching BS copies its bytes to new memory
-- and building one copies them back: O(n) each, with the same results.
module Data.ByteString.Internal (
    ByteString(BS, PS), unBS, bsFromString, packChars, c2w, w2c,
    fromForeignPtr, fromForeignPtr0, toForeignPtr, toForeignPtr0,
    create, unsafeCreate, createAndTrim, mallocByteString,
    createUptoN, unsafeCreateUptoN, createFp, unsafeCreateFp,
    plusForeignPtr, unsafeWithForeignPtr, memcpy, memset, memcmp, isSpaceWord8,
    unsafePackLenBytes, unsafePackLenChars,
    accursedUnutterablePerformIO, inlinePerformIO, unsafeDupablePerformIO,
    nullForeignPtr, c_strlen
  ) where

import Data.ByteString.Rep (ByteString, unBS, bsFromString, packChars, c2w, w2c)
import Data.Word (Word8)
import Foreign.ForeignPtr (ForeignPtr, mallocForeignPtrBytes, withForeignPtr, plusForeignPtr, newForeignPtr_)
import Foreign.Ptr (Ptr, nullPtr)
import Foreign.Marshal.Array (peekArray, pokeArray)
import Foreign.Marshal.Utils (copyBytes, fillBytes)
import Foreign.Storable (peekByteOff)
import System.IO.Unsafe (unsafePerformIO, unsafeDupablePerformIO)
import Foreign.C.String (CString)
import Foreign.C.Types (CSize)

pattern BS :: ForeignPtr Word8 -> Int -> ByteString
pattern BS fp len <- (toForeignPtr0 -> (fp, len))
  where BS fp len = fromForeignPtr0 fp len

-- bytestring 0.10's PS fp off len (network's Cmsg, base64-bytestring's)
pattern PS :: ForeignPtr Word8 -> Int -> Int -> ByteString
pattern PS fp off len <- (toForeignPtr -> (fp, off, len))
  where PS fp off len = fromForeignPtr fp off len

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

-- | At most N bytes; F answers how many it wrote.
createUptoN :: Int -> (Ptr Word8 -> IO Int) -> IO ByteString
createUptoN = createAndTrim

unsafeCreateUptoN :: Int -> (Ptr Word8 -> IO Int) -> ByteString
unsafeCreateUptoN n f = unsafePerformIO (createUptoN n f)

createFp :: Int -> (ForeignPtr Word8 -> IO ()) -> IO ByteString
createFp n f = do
  fp <- mallocByteString n
  f fp
  return (fromForeignPtr0 fp n)

unsafeCreateFp :: Int -> (ForeignPtr Word8 -> IO ()) -> ByteString
unsafeCreateFp n f = unsafePerformIO (createFp n f)

unsafeWithForeignPtr :: ForeignPtr a -> (Ptr a -> IO b) -> IO b
unsafeWithForeignPtr = withForeignPtr

memcpy :: Ptr Word8 -> Ptr Word8 -> Int -> IO ()
memcpy = copyBytes

memset :: Ptr Word8 -> Word8 -> Int -> IO (Ptr Word8)
memset p w n = fillBytes p w n >> return p

-- | As C's: negative, zero or positive as the first N bytes at P are below,
-- equal to or above those at Q.
memcmp :: Ptr Word8 -> Ptr Word8 -> Int -> IO Int
memcmp p q n = go 0
  where
    go i | i >= n = return 0
         | otherwise = do
             a <- peekByteOff p i :: IO Word8
             b <- peekByteOff q i :: IO Word8
             if a == b then go (i + 1) else return (fromIntegral a - fromIntegral b)

isSpaceWord8 :: Word8 -> Bool
isSpaceWord8 w = w == 32 || (w >= 9 && w <= 13) || w == 0xA0

-- | bytestring's strlen: the bytes before the first 0 (JHC's atoms).
c_strlen :: CString -> IO CSize
c_strlen p = go 0
  where go n = do b <- peekByteOff p n :: IO Word8
                  if b == 0 then return (fromIntegral n) else go (n + 1)
