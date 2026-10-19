-- Data.Text.Encoding (text): Text to and from encoded ByteStrings.
-- Yale Haskell's ByteStrings hold their bytes as Chars 0..255.
module Data.Text.Encoding (
    encodeUtf8, decodeUtf8, decodeUtf8', decodeUtf8With, decodeUtf8Lenient,
    decodeLatin1, decodeASCII, encodeUtf16LE, encodeUtf16BE, encodeUtf32LE,
    encodeUtf32BE, decodeUtf16LE, decodeUtf16BE, decodeUtf32LE, decodeUtf32BE,
    utf8Bytes, utf8DecodeWith
  ) where

import Control.Exception (evaluate, try)
import Data.Bits ((.&.), (.|.), shiftL, shiftR)
import Data.Char (chr, ord)
import qualified Data.ByteString as B
import Data.ByteString.Internal (unBS, bsFromString)
import qualified Data.Text as T
import Data.Text.Encoding.Error
import System.IO.Unsafe (unsafePerformIO)

-- the UTF-8 bytes of a String, as Chars
utf8Bytes :: String -> String
utf8Bytes = concatMap (map chr . enc . ord)
  where enc n
          | n < 0x80 = [n]
          | n < 0x800 = [0xC0 .|. shiftR n 6, 0x80 .|. (n .&. 0x3F)]
          | n < 0x10000 = [0xE0 .|. shiftR n 12, 0x80 .|. (shiftR n 6 .&. 0x3F),
                           0x80 .|. (n .&. 0x3F)]
          | otherwise = [0xF0 .|. shiftR n 18, 0x80 .|. (shiftR n 12 .&. 0x3F),
                         0x80 .|. (shiftR n 6 .&. 0x3F), 0x80 .|. (n .&. 0x3F)]

-- decode UTF-8 bytes (Chars 0..255), invalid ones given to the handler
utf8DecodeWith :: OnDecodeError -> String -> String
utf8DecodeWith onErr = go
  where
    go [] = []
    go (c : cs)
      | b < 0x80 = c : go cs
      | b >= 0xC2 && b < 0xE0 = multi 1 (b .&. 0x1F) 0x80 cs
      | b >= 0xE0 && b < 0xF0 = multi 2 (b .&. 0x0F) 0x800 cs
      | b >= 0xF0 && b < 0xF5 = multi 3 (b .&. 0x07) 0x10000 cs
      | otherwise = bad b cs
      where b = ord c
    multi k acc minv cs =
      let (conts, rest) = splitAt k cs
      in if length conts == k && all (\x -> ord x .&. 0xC0 == 0x80) conts
           then let v = foldl (\a x -> shiftL a 6 .|. (ord x .&. 0x3F)) acc conts
                in if v < minv || v > 0x10FFFF || (v >= 0xD800 && v <= 0xDFFF)
                     then bad (ord (head' cs)) cs
                     else chr v : go rest
           else bad (ord (head' cs)) cs
      where head' (x : _) = x
            head' [] = '\0'
    bad b rest = case onErr "Data.Text.Internal.Encoding: Invalid UTF-8 stream"
                            (Just (fromIntegral b)) of
                   Just r -> r : go rest
                   Nothing -> go rest

encodeUtf8 :: T.Text -> B.ByteString
encodeUtf8 t = bsFromString (utf8Bytes (T.unpack t))

decodeUtf8With :: OnDecodeError -> B.ByteString -> T.Text
decodeUtf8With onErr b = T.pack (utf8DecodeWith onErr (unBS b))

decodeUtf8 :: B.ByteString -> T.Text
decodeUtf8 = decodeUtf8With strictDecode

decodeUtf8Lenient :: B.ByteString -> T.Text
decodeUtf8Lenient = decodeUtf8With lenientDecode

decodeUtf8' :: B.ByteString -> Either UnicodeException T.Text
decodeUtf8' b = unsafePerformIO (try (evaluate (forceText (decodeUtf8 b))))
  where forceText t = T.length t `seq` t

decodeLatin1 :: B.ByteString -> T.Text
decodeLatin1 b = T.pack (unBS b)

decodeASCII :: B.ByteString -> T.Text
decodeASCII = decodeLatin1

bytesOf :: Int -> Bool -> Int -> String
bytesOf k bigEnd n =
  let bs = [ chr ((n `shiftR` (8 * i)) .&. 0xFF) | i <- [0 .. k - 1] ]
  in if bigEnd then reverse bs else bs

utf16 :: Bool -> String -> String
utf16 be = concatMap unit
  where unit c | ord c < 0x10000 = bytesOf 2 be (ord c)
               | otherwise = let v = ord c - 0x10000
                             in bytesOf 2 be (0xD800 + shiftR v 10) ++
                                bytesOf 2 be (0xDC00 + (v .&. 0x3FF))

encodeUtf16LE, encodeUtf16BE, encodeUtf32LE, encodeUtf32BE :: T.Text -> B.ByteString
encodeUtf16LE t = bsFromString (utf16 False (T.unpack t))
encodeUtf16BE t = bsFromString (utf16 True (T.unpack t))
encodeUtf32LE t = bsFromString (concatMap (bytesOf 4 False . ord) (T.unpack t))
encodeUtf32BE t = bsFromString (concatMap (bytesOf 4 True . ord) (T.unpack t))

words16 :: Bool -> String -> [Int]
words16 be (a : b : rest) =
  (if be then ord a * 256 + ord b else ord b * 256 + ord a) : words16 be rest
words16 _ _ = []

fromUtf16 :: [Int] -> String
fromUtf16 (h : l : rest)
  | h >= 0xD800 && h < 0xDC00 && l >= 0xDC00 && l < 0xE000 =
      chr (0x10000 + shiftL (h - 0xD800) 10 + (l - 0xDC00)) : fromUtf16 rest
fromUtf16 (w : rest) = chr w : fromUtf16 rest
fromUtf16 [] = []

decodeUtf16LE, decodeUtf16BE, decodeUtf32LE, decodeUtf32BE :: B.ByteString -> T.Text
decodeUtf16LE b = T.pack (fromUtf16 (words16 False (unBS b)))
decodeUtf16BE b = T.pack (fromUtf16 (words16 True (unBS b)))
decodeUtf32LE b = T.pack (words32 False (unBS b))
decodeUtf32BE b = T.pack (words32 True (unBS b))

words32 :: Bool -> String -> String
words32 be (a : b : c : d : rest) =
  let ws = map ord (if be then [a, b, c, d] else [d, c, b, a])
  in chr (foldl (\x y -> x * 256 + y) 0 ws) : words32 be rest
words32 _ _ = []
