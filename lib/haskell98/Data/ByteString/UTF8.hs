-- Data.ByteString.UTF8 (utf8-string): ByteStrings as UTF-8 text.
module Data.ByteString.UTF8 (
    ByteString, fromString, toString, decode, uncons, length, take, drop,
    splitAt, lines
  ) where

import Prelude hiding (length, take, drop, splitAt, lines)
import qualified Prelude as P
import Data.Char (chr, ord)
import Data.Bits ((.&.), (.|.), shiftL, shiftR)
import Data.ByteString.Rep (ByteString, unBS, bsFromString)

fromString :: String -> ByteString
fromString s = bsFromString (concatMap encodeChar s)

encodeChar :: Char -> String
encodeChar c
  | n < 0x80 = [c]
  | n < 0x800 = map chr [0xC0 .|. shiftR n 6, 0x80 .|. (n .&. 0x3F)]
  | n < 0x10000 = map chr [0xE0 .|. shiftR n 12, 0x80 .|. (shiftR n 6 .&. 0x3F),
                           0x80 .|. (n .&. 0x3F)]
  | otherwise = map chr [0xF0 .|. shiftR n 18, 0x80 .|. (shiftR n 12 .&. 0x3F),
                         0x80 .|. (shiftR n 6 .&. 0x3F), 0x80 .|. (n .&. 0x3F)]
  where n = ord c

toString :: ByteString -> String
toString b = go (unBS b)
  where go [] = []
        go cs = case decodeChars cs of (c, _, rest) -> c : go rest

-- the first character, the bytes it took and the rest; a bad byte is
-- U+FFFD, as utf8-string decodes it
decodeChars :: String -> (Char, Int, String)
decodeChars (c : cs)
  | n < 0x80 = (c, 1, cs)
  | n >= 0xF0 = multi 3 (n .&. 0x07)
  | n >= 0xE0 = multi 2 (n .&. 0x0F)
  | n >= 0xC0 = multi 1 (n .&. 0x1F)
  | otherwise = ('\xFFFD', 1, cs)
  where n = ord c
        multi k acc =
          let (conts, rest) = P.splitAt k cs
          in if P.length conts == k && all (\x -> ord x .&. 0xC0 == 0x80) conts
               then (chr (foldl (\a x -> shiftL a 6 .|. (ord x .&. 0x3F)) acc conts),
                     k + 1, rest)
               else ('\xFFFD', 1, cs)
decodeChars [] = error "Data.ByteString.UTF8: empty"

decode :: ByteString -> Maybe (Char, Int)
decode b = case unBS b of
  [] -> Nothing
  s -> case decodeChars s of (c, k, _) -> Just (c, k)

uncons :: ByteString -> Maybe (Char, ByteString)
uncons b = case unBS b of
  [] -> Nothing
  s -> case decodeChars s of (c, _, rest) -> Just (c, bsFromString rest)

length :: ByteString -> Int
length = P.length . toString

take, drop :: Int -> ByteString -> ByteString
take n = fromString . P.take n . toString
drop n = fromString . P.drop n . toString

splitAt :: Int -> ByteString -> (ByteString, ByteString)
splitAt n b = (take n b, drop n b)

lines :: ByteString -> [ByteString]
lines = map fromString . P.lines . toString
