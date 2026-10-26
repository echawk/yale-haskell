-- Data.ByteString.Builder (bytestring): a difference list of Chars.
module Data.ByteString.Builder (
    Builder, toLazyByteString, hPutBuilder, byteString, lazyByteString,
    char7, string7, char8, string8, charUtf8, stringUtf8, intDec,
    integerDec, int8Dec, int16Dec, int32Dec, int64Dec, wordDec, word8Dec,
    doubleDec, floatDec, word8, int8, wordHex, word8Hex, word16Hex,
    word32Hex, word64Hex, shortByteString,
    word16Dec, word32Dec, word64Dec, int16BE, int16LE, int32BE, int32LE,
    floatBE, floatLE, doubleBE, doubleLE, floatHost, doubleHost,
    int64BE, int64LE, word16BE, word16LE, word32BE, word32LE, word64BE,
    word64LE, doubleHexFixed, word8HexFixed, word16HexFixed, word32HexFixed,
    word64HexFixed, int8HexFixed, int16HexFixed, int32HexFixed, int64HexFixed
  ) where

import Data.ByteString.Short (ShortByteString, fromShort)
import PreludeModern (Semigroup((<>)), Monoid(mempty))
import Data.ByteString.Rep
import qualified Data.ByteString.Lazy.Internal as L
import Data.Word
import Data.Int
import Numeric (showHex)
import System.IO (Handle, hPutStr)
import Data.String (IsString(fromString))
import GHC.Float (castFloatToWord32, castDoubleToWord64)

newtype Builder = Builder (String -> String)

instance Semigroup Builder where
  Builder f <> Builder g = Builder (f . g)
instance Monoid Builder where
  mempty = Builder id
instance Show Builder where
  show b = show (toLazyByteString b)

toLazyByteString :: Builder -> L.ByteString
toLazyByteString (Builder f) = L.LBS (bsFromString (f ""))

hPutBuilder :: Handle -> Builder -> IO ()
hPutBuilder h (Builder f) = hPutStr h (f "")

str :: String -> Builder
str s = Builder (s ++)

byteString :: ByteString -> Builder
byteString b = str (unBS b)

lazyByteString :: L.ByteString -> Builder
lazyByteString (L.LBS b) = str (unBS b)

char7, char8, charUtf8 :: Char -> Builder
char7 c = Builder (c :)
char8 c = Builder (c :)
charUtf8 c = Builder (c :)

string7, string8, stringUtf8 :: String -> Builder
string7 = str
string8 = str
stringUtf8 = str

intDec :: Int -> Builder
intDec n = Builder (shows n)
integerDec :: Integer -> Builder
integerDec n = Builder (shows n)
int8Dec :: Int8 -> Builder
int8Dec n = Builder (shows n)
int16Dec :: Int16 -> Builder
int16Dec n = Builder (shows n)
int32Dec :: Int32 -> Builder
int32Dec n = Builder (shows n)
int64Dec :: Int64 -> Builder
int64Dec n = Builder (shows n)
wordDec :: Word -> Builder
wordDec n = Builder (shows n)
word8Dec :: Word8 -> Builder
word8Dec n = Builder (shows n)
doubleDec :: Double -> Builder
doubleDec d = Builder (shows d)
floatDec :: Float -> Builder
floatDec d = Builder (shows d)

word8 :: Word8 -> Builder
word8 w = Builder (w2c w :)
int8 :: Int8 -> Builder
int8 i = Builder (toEnum (fromIntegral i `mod` 256) :)

wordHex :: Word -> Builder
wordHex w = Builder (showHex w)
word8Hex :: Word8 -> Builder
word8Hex w = Builder (showHex w)
word16Hex :: Word16 -> Builder
word16Hex w = Builder (showHex w)
word32Hex :: Word32 -> Builder
word32Hex w = Builder (showHex w)
word64Hex :: Word64 -> Builder
word64Hex w = Builder (showHex w)

shortByteString :: ShortByteString -> Builder
shortByteString = byteString . fromShort

word16Dec :: Word16 -> Builder
word16Dec n = Builder (shows n)
word32Dec :: Word32 -> Builder
word32Dec n = Builder (shows n)
word64Dec :: Word64 -> Builder
word64Dec n = Builder (shows n)

-- n bytes of x, big-endian
bytesBE :: Int -> Integer -> Builder
bytesBE n x = Builder (\r -> [ toEnum (fromInteger ((x `div` (256 ^ k)) `mod` 256)) | k <- reverse [0 .. n - 1] ] ++ r)

bytesLE :: Int -> Integer -> Builder
bytesLE n x = Builder (\r -> [ toEnum (fromInteger ((x `div` (256 ^ k)) `mod` 256)) | k <- [0 .. n - 1] ] ++ r)

-- (two's complement, as the bytes of the unsigned value)
unsigned :: Int -> Integer -> Integer
unsigned n x = x `mod` (256 ^ n)

int16BE, int16LE :: Int16 -> Builder
int16BE = bytesBE 2 . unsigned 2 . toInteger
int16LE = bytesLE 2 . unsigned 2 . toInteger
int32BE, int32LE :: Int32 -> Builder
int32BE = bytesBE 4 . unsigned 4 . toInteger
int32LE = bytesLE 4 . unsigned 4 . toInteger
int64BE, int64LE :: Int64 -> Builder
int64BE = bytesBE 8 . unsigned 8 . toInteger
int64LE = bytesLE 8 . unsigned 8 . toInteger
word16BE, word16LE :: Word16 -> Builder
word16BE = bytesBE 2 . toInteger
word16LE = bytesLE 2 . toInteger
word32BE, word32LE :: Word32 -> Builder
word32BE = bytesBE 4 . toInteger
word32LE = bytesLE 4 . toInteger
word64BE, word64LE :: Word64 -> Builder
word64BE = bytesBE 8 . toInteger
word64LE = bytesLE 8 . toInteger

-- IEEE 754 bits (GHC.Float's casts)
floatBE, floatLE, floatHost :: Float -> Builder
floatBE = word32BE . castFloatToWord32
floatLE = word32LE . castFloatToWord32
floatHost = floatLE
doubleBE, doubleLE, doubleHost :: Double -> Builder
doubleBE = word64BE . castDoubleToWord64
doubleLE = word64LE . castDoubleToWord64
doubleHost = doubleLE

-- lowercase hexadecimal, all the digits
hexFixed :: Int -> Integer -> Builder
hexFixed n x = Builder (\r -> [ "0123456789abcdef" !! fromInteger ((x `div` (16 ^ k)) `mod` 16)
                              | k <- reverse [0 .. n - 1] ] ++ r)

word8HexFixed :: Word8 -> Builder
word8HexFixed = hexFixed 2 . toInteger
word16HexFixed :: Word16 -> Builder
word16HexFixed = hexFixed 4 . toInteger
word32HexFixed :: Word32 -> Builder
word32HexFixed = hexFixed 8 . toInteger
word64HexFixed :: Word64 -> Builder
word64HexFixed = hexFixed 16 . toInteger
int8HexFixed :: Int8 -> Builder
int8HexFixed = hexFixed 2 . unsigned 1 . toInteger
int16HexFixed :: Int16 -> Builder
int16HexFixed = hexFixed 4 . unsigned 2 . toInteger
int32HexFixed :: Int32 -> Builder
int32HexFixed = hexFixed 8 . unsigned 4 . toInteger
int64HexFixed :: Int64 -> Builder
int64HexFixed = hexFixed 16 . unsigned 8 . toInteger

-- | The IEEE bits (as castDoubleToWord64).
doubleHexFixed :: Double -> Builder
doubleHexFixed d = hexFixed 16 (doubleBits d)

doubleBits :: Double -> Integer
doubleBits d
  | d == 0 = if isNegativeZero d then 2 ^ 63 else 0
  | isNaN d = 0x7FF8000000000000
  | isInfinite d = if d > 0 then 0x7FF0000000000000 else 0xFFF0000000000000
  | otherwise =
      let (m, e) = decodeFloat (abs d)
          sign = if d < 0 then 2 ^ 63 else 0
          e' = e + 52 + 1023
      in if e' <= 0
           then sign + (m `div` (2 ^ (1 - e')))
           else sign + toInteger e' * 2 ^ 52 + (m - 2 ^ 52)

-- | As bytestring's: the String's UTF-8.
instance IsString Builder where
  fromString = stringUtf8
