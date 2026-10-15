-- Data.ByteString.Builder (bytestring): a difference list of Chars.
module Data.ByteString.Builder (
    Builder, toLazyByteString, hPutBuilder, byteString, lazyByteString,
    char7, string7, char8, string8, charUtf8, stringUtf8, intDec,
    integerDec, int8Dec, int16Dec, int32Dec, int64Dec, wordDec, word8Dec,
    doubleDec, floatDec, word8, int8, wordHex, word8Hex, word16Hex,
    word32Hex, word64Hex
  ) where

import PreludeModern (Semigroup((<>)), Monoid(mempty))
import Data.ByteString.Internal
import Data.Word
import Data.Int
import Numeric (showHex)
import System.IO (Handle, hPutStr)

newtype Builder = Builder (String -> String)

instance Semigroup Builder where
  Builder f <> Builder g = Builder (f . g)
instance Monoid Builder where
  mempty = Builder id
instance Show Builder where
  show b = show (toLazyByteString b)

toLazyByteString :: Builder -> ByteString
toLazyByteString (Builder f) = bsFromString (f "")

hPutBuilder :: Handle -> Builder -> IO ()
hPutBuilder h (Builder f) = hPutStr h (f "")

str :: String -> Builder
str s = Builder (s ++)

byteString, lazyByteString :: ByteString -> Builder
byteString b = str (unBS b)
lazyByteString b = str (unBS b)

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
