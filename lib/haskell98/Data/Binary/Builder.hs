-- Data.Binary.Builder (binary): a difference list of bytes (Chars
-- 0..255), made into a lazy ByteString.
module Data.Binary.Builder (
    Builder, toLazyByteString, empty, singleton, append, fromByteString,
    fromLazyByteString, flush, putWord16be, putWord32be, putWord64be,
    putWord16le, putWord32le, putWord64le, putWordhost, putWord16host,
    putWord32host, putWord64host, putInt16be, putInt32be, putInt64be,
    putInt16le, putInt32le, putInt64le, putInthost, putInt16host,
    putInt32host, putInt64host, putCharUtf8, putStringUtf8,
    -- for Data.Binary.Put
    fromBytesString, bigEndianBytes, littleEndianBytes
  ) where

import PreludeModern (Semigroup((<>)), Monoid(mempty, mappend, mconcat))
import qualified Data.ByteString as S
import qualified Data.ByteString.Lazy as L
import Data.ByteString.Rep (unBS, bsFromString)
import qualified Data.ByteString.Lazy.Internal as LI
import Data.Int
import Data.Word
import Data.Char (chr, ord)
import Data.Bits ((.&.), shiftR)

newtype Builder = Builder (String -> String)

instance Semigroup Builder where
  Builder f <> Builder g = Builder (f . g)
instance Monoid Builder where
  mempty = Builder id
  mappend = (<>)

toLazyByteString :: Builder -> L.ByteString
toLazyByteString (Builder f) = LI.LBS (bsFromString (f []))

empty :: Builder
empty = mempty

append :: Builder -> Builder -> Builder
append = (<>)

fromBytesString :: String -> Builder
fromBytesString s = Builder (s ++)

singleton :: Word8 -> Builder
singleton w = Builder (chr (fromIntegral w) :)

fromByteString :: S.ByteString -> Builder
fromByteString b = fromBytesString (unBS b)

fromLazyByteString :: L.ByteString -> Builder
fromLazyByteString (LI.LBS b) = fromByteString b

flush :: Builder
flush = mempty

-- the k bytes of x (mod 256^k)
bigEndianBytes :: Int -> Integer -> Builder
bigEndianBytes k x = fromBytesString [ chr (fromInteger ((x `div` (256 ^ i)) `mod` 256))
                                     | i <- [k - 1, k - 2 .. 0] ]

littleEndianBytes :: Int -> Integer -> Builder
littleEndianBytes k x = fromBytesString [ chr (fromInteger ((x `div` (256 ^ i)) `mod` 256))
                                        | i <- [0 .. k - 1] ]

putWord16be, putWord16le, putWord16host :: Word16 -> Builder
putWord16be = bigEndianBytes 2 . toInteger
putWord16le = littleEndianBytes 2 . toInteger
putWord16host = putWord16le
putWord32be, putWord32le, putWord32host :: Word32 -> Builder
putWord32be = bigEndianBytes 4 . toInteger
putWord32le = littleEndianBytes 4 . toInteger
putWord32host = putWord32le
putWord64be, putWord64le, putWord64host :: Word64 -> Builder
putWord64be = bigEndianBytes 8 . toInteger
putWord64le = littleEndianBytes 8 . toInteger
putWord64host = putWord64le
putWordhost :: Word -> Builder
putWordhost = littleEndianBytes 8 . toInteger
putInt16be, putInt16le, putInt16host :: Int16 -> Builder
putInt16be = bigEndianBytes 2 . toInteger
putInt16le = littleEndianBytes 2 . toInteger
putInt16host = putInt16le
putInt32be, putInt32le, putInt32host :: Int32 -> Builder
putInt32be = bigEndianBytes 4 . toInteger
putInt32le = littleEndianBytes 4 . toInteger
putInt32host = putInt32le
putInt64be, putInt64le, putInt64host :: Int64 -> Builder
putInt64be = bigEndianBytes 8 . toInteger
putInt64le = littleEndianBytes 8 . toInteger
putInt64host = putInt64le
putInthost :: Int -> Builder
putInthost = littleEndianBytes 8 . toInteger

putCharUtf8 :: Char -> Builder
putCharUtf8 c = fromBytesString (map chr (utf8 (ord c)))

putStringUtf8 :: String -> Builder
putStringUtf8 = mconcat . map putCharUtf8

utf8 :: Int -> [Int]
utf8 n
  | n < 0x80 = [n]
  | n < 0x800 = [0xC0 + shiftR n 6, 0x80 + n .&. 0x3F]
  | n < 0x10000 = [0xE0 + shiftR n 12, 0x80 + shiftR n 6 .&. 0x3F, 0x80 + n .&. 0x3F]
  | otherwise = [0xF0 + shiftR n 18, 0x80 + shiftR n 12 .&. 0x3F,
                 0x80 + shiftR n 6 .&. 0x3F, 0x80 + n .&. 0x3F]
