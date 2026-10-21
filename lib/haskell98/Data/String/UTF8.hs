{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}
-- Data.String.UTF8 (utf8-string): strings as UTF-8 bytes in a container,
-- here operated on by decoding to String and encoding back.
module Data.String.UTF8 (
    UTF8, UTF8Bytes(..), fromString, toString, fromRep, toRep,
    replacement_char, uncons, splitAt, take, drop, span, break, foldl,
    foldr, length, lines, lines', null, decode, byteSplitAt, byteTake,
    byteDrop
  ) where

import Prelude hiding (splitAt, take, drop, span, break, foldl, foldr,
                       length, lines, null)
import qualified Prelude as P
import qualified Data.List as L
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import Data.Bits ((.&.), (.|.), shiftL, shiftR)
import Data.Char (chr, ord)
import Data.Word (Word8)
import Data.Int (Int64)

newtype UTF8 string = Str string deriving (Eq, Ord)

instance UTF8Bytes string index => Show (UTF8 string) where
  show = show . toString

-- | A container of bytes, indexed by INDEX.
class (Num index, Integral index) => UTF8Bytes bytestring index
    | bytestring -> index where
  bsplit :: index -> bytestring -> (bytestring, bytestring)
  bdrop :: index -> bytestring -> bytestring
  buncons :: bytestring -> Maybe (Word8, bytestring)
  tail :: bytestring -> bytestring
  elemIndex :: Word8 -> bytestring -> Maybe index
  empty :: bytestring
  null :: bytestring -> Bool
  pack :: [Word8] -> bytestring
  unpackBytes :: bytestring -> [Word8]

instance UTF8Bytes B.ByteString Int where
  bsplit = B.splitAt
  bdrop = B.drop
  buncons = B.uncons
  tail = B.tail
  elemIndex = B.elemIndex
  empty = B.empty
  null = B.null
  pack = B.pack
  unpackBytes = B.unpack

instance UTF8Bytes BL.ByteString Int64 where
  bsplit = BL.splitAt
  bdrop = BL.drop
  buncons = BL.uncons
  tail = BL.tail
  elemIndex = BL.elemIndex
  empty = BL.empty
  null = BL.null
  pack = BL.pack
  unpackBytes = BL.unpack

instance UTF8Bytes [Word8] Int where
  bsplit = P.splitAt
  bdrop = P.drop
  buncons [] = Nothing
  buncons (x : xs) = Just (x, xs)
  tail = P.tail
  elemIndex = L.elemIndex
  empty = []
  null = P.null
  pack = id
  unpackBytes = id

replacement_char :: Char
replacement_char = '\xfffd'

fromRep :: string -> UTF8 string
fromRep = Str

toRep :: UTF8 string -> string
toRep (Str s) = s

fromString :: UTF8Bytes string index => String -> UTF8 string
fromString = Str . pack . concatMap encodeChar

toString :: UTF8Bytes string index => UTF8 string -> String
toString (Str s) = decodeBytes (unpackBytes s)

-- the characters, through String
chars :: UTF8Bytes string index => UTF8 string -> String
chars = toString

uncons :: UTF8Bytes string index => UTF8 string -> Maybe (Char, UTF8 string)
uncons s = case chars s of
  [] -> Nothing
  (c : cs) -> Just (c, fromString cs)

splitAt :: UTF8Bytes string index => index -> UTF8 string -> (UTF8 string, UTF8 string)
splitAt n s = let (a, b) = P.splitAt (fromIntegral n) (chars s) in (fromString a, fromString b)

take, drop :: UTF8Bytes string index => index -> UTF8 string -> UTF8 string
take n = fst . splitAt n
drop n = snd . splitAt n

span, break :: UTF8Bytes string index => (Char -> Bool) -> UTF8 string -> (UTF8 string, UTF8 string)
span p s = let (a, b) = P.span p (chars s) in (fromString a, fromString b)
break p = span (not . p)

foldl :: UTF8Bytes string index => (a -> Char -> a) -> a -> UTF8 string -> a
foldl f z = L.foldl' f z . chars

foldr :: UTF8Bytes string index => (Char -> a -> a) -> a -> UTF8 string -> a
foldr f z = P.foldr f z . chars

length :: UTF8Bytes string index => UTF8 string -> index
length = fromIntegral . P.length . chars

lines :: UTF8Bytes string index => UTF8 string -> [UTF8 string]
lines = map fromString . P.lines . chars

-- | As lines, keeping the newlines.
lines' :: UTF8Bytes string index => UTF8 string -> [UTF8 string]
lines' = map fromString . go . chars
  where go [] = []
        go s = case P.break (== '\n') s of
          (l, '\n' : rest) -> (l ++ "\n") : go rest
          (l, _) -> [l]

-- | The first character and the bytes it took, or Nothing.
decode :: UTF8Bytes string index => string -> Maybe (Char, index)
decode s = case unpackBytes s of
  [] -> Nothing
  bs -> let (c, n) = decodeOne bs in Just (c, fromIntegral n)

byteSplitAt :: UTF8Bytes string index => index -> UTF8 string -> (UTF8 string, UTF8 string)
byteSplitAt n (Str s) = let (a, b) = bsplit n s in (Str a, Str b)

byteTake, byteDrop :: UTF8Bytes string index => index -> UTF8 string -> UTF8 string
byteTake n = fst . byteSplitAt n
byteDrop n = snd . byteSplitAt n

encodeChar :: Char -> [Word8]
encodeChar c
  | n < 0x80 = [fromIntegral n]
  | n < 0x800 = map fromIntegral [0xC0 .|. shiftR n 6, 0x80 .|. (n .&. 0x3F)]
  | n < 0x10000 = map fromIntegral [0xE0 .|. shiftR n 12, 0x80 .|. (shiftR n 6 .&. 0x3F),
                                    0x80 .|. (n .&. 0x3F)]
  | otherwise = map fromIntegral [0xF0 .|. shiftR n 18, 0x80 .|. (shiftR n 12 .&. 0x3F),
                                  0x80 .|. (shiftR n 6 .&. 0x3F), 0x80 .|. (n .&. 0x3F)]
  where n = ord c

decodeBytes :: [Word8] -> String
decodeBytes [] = []
decodeBytes bs = let (c, n) = decodeOne bs in c : decodeBytes (P.drop n bs)

-- one character and its byte count (a malformed one: the replacement)
decodeOne :: [Word8] -> (Char, Int)
decodeOne (b : rest)
  | b < 0x80 = (chr (fromIntegral b), 1)
  | b < 0xE0 = multi 1 (fromIntegral b .&. 0x1F)
  | b < 0xF0 = multi 2 (fromIntegral b .&. 0x0F)
  | otherwise = multi 3 (fromIntegral b .&. 0x07)
  where
    multi k start =
      let cont = P.take k rest
      in if P.length cont == k && all (\x -> x .&. 0xC0 == 0x80) cont
           then (chr (P.foldl (\a x -> shiftL a 6 .|. (fromIntegral x .&. 0x3F)) start cont), k + 1)
           else (replacement_char, 1)
decodeOne [] = (replacement_char, 0)
