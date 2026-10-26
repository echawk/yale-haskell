{-# LANGUAGE PatternSynonyms, ViewPatterns, MagicHash, UnboxedTuples #-}
-- Data.ByteString.Short (bytestring): ShortByteString.  Yale Haskell's
-- ByteString is already one packed string (Data.ByteString), so a
-- ShortByteString holds one and the conversions are free; it is a type
-- of its own, as bytestring's, so that a class may have instances for
-- both (digest's CRC32C).
module Data.ByteString.Short (
    ShortByteString(SBS), toShort, fromShort, pack, unpack, empty, null, length,
    index, indexMaybe, (!?), append, concat
  ) where

import Prelude hiding (null, length, concat)
import qualified Prelude as P
import qualified Data.ByteString as B
import Data.ByteString (ByteString)
import Data.ByteString.Short.Rep (ShortByteString(..))
import Data.Word (Word8)
import Data.ByteString.Rep (unBS, bsFromString, c2w, w2c)
import GHC.Exts

toShort :: ByteString -> ShortByteString
toShort = ShortByteString

fromShort :: ShortByteString -> ByteString
fromShort (ShortByteString b) = b

pack :: [Word8] -> ShortByteString
pack = toShort . B.pack

unpack :: ShortByteString -> [Word8]
unpack = B.unpack . fromShort

empty :: ShortByteString
empty = toShort B.empty

null :: ShortByteString -> Bool
null = B.null . fromShort

length :: ShortByteString -> Int
length = B.length . fromShort

index :: ShortByteString -> Int -> Word8
index s = B.index (fromShort s)

indexMaybe, (!?) :: ShortByteString -> Int -> Maybe Word8
indexMaybe s = B.indexMaybe (fromShort s)
(!?) = indexMaybe

append :: ShortByteString -> ShortByteString -> ShortByteString
append a b = toShort (B.append (fromShort a) (fromShort b))

concat :: [ShortByteString] -> ShortByteString
concat = toShort . B.concat . map fromShort

-- bytestring 0.11.1's constructor, a byte array (copied each way)
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
