-- The ByteString type of Data.ByteString and its friends (bytestring):
-- a packed string of Chars 0..255, one per byte (a Data.Text.Rep Text,
-- so the Text primitives serve both).  Lazy and strict ByteStrings are
-- the same type here (fromStrict and toStrict are id).  Not the real
-- Data.ByteString.Internal, whose pointers do not exist here (that
-- module shows these as bytestring's: Data/ByteString/Internal.hs).
module Data.ByteString.Rep (
    ByteString(BS), unBS, bsFromString, packChars, c2w, w2c
  ) where

import PreludeModern (Semigroup((<>)), Monoid(mempty))
import Data.String (IsString(fromString))
import Data.Word (Word8)
import qualified Data.Text as T
import Data.Text.Rep (Text)

newtype ByteString = BS Text

-- the bytes as Chars
unBS :: ByteString -> String
unBS (BS t) = T.unpack t

-- Chars already 0..255
bsFromString :: String -> ByteString
bsFromString s = BS (T.pack s)

instance Eq ByteString where
  BS a == BS b = a == b
instance Ord ByteString where
  compare (BS a) (BS b) = compare a b
instance Show ByteString where
  showsPrec p (BS t) = showsPrec p t
instance Read ByteString where
  readsPrec p s = [(packChars x, r) | (x, r) <- readsPrec p s]
instance Semigroup ByteString where
  BS a <> BS b = BS (T.append a b)
instance Monoid ByteString where
  mempty = BS T.empty
instance IsString ByteString where
  fromString = packChars

-- truncated to bytes, as Char8.pack does
packChars :: String -> ByteString
packChars s = bsFromString (map (\c -> if c > '\255' then toEnum (fromEnum c `mod` 256) else c) s)

c2w :: Char -> Word8
c2w = fromIntegral . fromEnum

w2c :: Word8 -> Char
w2c = toEnum . fromIntegral
