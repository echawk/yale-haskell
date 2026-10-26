-- Data.ByteString.Short (bytestring): ShortByteString.  Yale Haskell's
-- ByteString is already one packed string (Data.ByteString), so a
-- ShortByteString holds one and the conversions are free; it is a type
-- of its own, as bytestring's, so that a class may have instances for
-- both (digest's CRC32C).
module Data.ByteString.Short (
    ShortByteString, toShort, fromShort, pack, unpack, empty, null, length,
    index, indexMaybe, (!?), append, concat
  ) where

import Prelude hiding (null, length, concat)
import qualified Data.ByteString as B
import Data.ByteString (ByteString)
import Data.ByteString.Short.Rep (ShortByteString(..))
import Data.Word (Word8)

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
