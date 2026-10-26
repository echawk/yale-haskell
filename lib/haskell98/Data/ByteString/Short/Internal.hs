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
import Data.ByteString.Short (ShortByteString, pattern SBS, toShort, fromShort, length)
import Data.ByteString.Rep (unBS, bsFromString, c2w, w2c)
import Data.Word (Word8)
import Foreign.Ptr (Ptr, plusPtr)
import Foreign.Marshal.Array (peekArray)
import GHC.Exts

-- | The LEN bytes at OFF from P.
createFromPtr :: Ptr a -> Int -> IO ShortByteString
createFromPtr p len = fmap (toShort . bsFromString . map w2c) (peekArray len (castW8 p))
  where castW8 :: Ptr a -> Ptr Word8
        castW8 q = q `plusPtr` 0

unsafeIndex :: ShortByteString -> Int -> Word8
unsafeIndex bs i = c2w (unBS (fromShort bs) !! i)

