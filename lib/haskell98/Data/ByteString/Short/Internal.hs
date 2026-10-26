{-# LANGUAGE PatternSynonyms, ViewPatterns, MagicHash, UnboxedTuples #-}
-- Data.ByteString.Short.Internal (bytestring 0.11): a ShortByteString
-- shown as a byte array, SBS arr.  ShortByteString holds a ByteString
-- here (Data.ByteString.Short); matching SBS copies the bytes into a new
-- array, building one copies them back.
module Data.ByteString.Short.Internal (
    ShortByteString, pattern SBS, toShort, fromShort, createFromPtr,
    unsafeIndex, length
  ) where

import Prelude hiding (length)
import qualified Prelude as P
import Data.ByteString.Short (ShortByteString, toShort, fromShort)
import Data.ByteString.Rep (unBS, bsFromString, c2w, w2c)
import Data.Word (Word8)
import Foreign.Ptr (Ptr, plusPtr)
import Foreign.Marshal.Array (peekArray)
import GHC.Exts

pattern SBS :: ByteArray# -> ShortByteString
pattern SBS arr <- (toByteArray -> ByteArrayBox arr)
  where SBS arr = fromByteArray arr

data ByteArrayBox = ByteArrayBox ByteArray#

toByteArray :: ShortByteString -> ByteArrayBox
toByteArray bs =
  let ws = map c2w (unBS (fromShort bs))
      n = P.length ws
  in runRW# (\s -> case newByteArray# n s of
       (# s1, mb #) -> case fill mb 0 ws s1 of
         s2 -> case unsafeFreezeByteArray# mb s2 of (# _, b #) -> ByteArrayBox b)
  where fill _ _ [] s = s
        fill mb i (w : rest) s = fill mb (i + 1) rest (writeWord8Array# mb i (fromIntegral w) s)

fromByteArray :: ByteArray# -> ShortByteString
fromByteArray b = toShort (bsFromString [ w2c (fromIntegral (indexWord8Array# b i))
                                       | i <- [0 .. sizeofByteArray# b - 1] ])

-- | The LEN bytes at OFF from P.
createFromPtr :: Ptr a -> Int -> IO ShortByteString
createFromPtr p len = fmap (toShort . bsFromString . map w2c) (peekArray len (castW8 p))
  where castW8 :: Ptr a -> Ptr Word8
        castW8 q = q `plusPtr` 0

unsafeIndex :: ShortByteString -> Int -> Word8
unsafeIndex bs i = c2w (unBS (fromShort bs) !! i)

length :: ShortByteString -> Int
length = P.length . unBS . fromShort
