-- The ByteString type of Data.ByteString and its friends (bytestring):
-- a String of Chars 0..255, one per byte.  Lazy and strict ByteStrings
-- are the same type here (fromStrict and toStrict are id).  Not the
-- real Data.ByteString.Internal, whose pointers do not exist here.
module Data.ByteString.Internal (
    ByteString(BS), unBS, packChars, c2w, w2c
  ) where

import PreludeModern (Semigroup((<>)), Monoid(mempty))
import Data.String (IsString(fromString))
import Data.Word (Word8)

newtype ByteString = BS String

unBS :: ByteString -> String
unBS (BS s) = s

instance Eq ByteString where
  BS a == BS b = a == b
instance Ord ByteString where
  compare (BS a) (BS b) = compare a b
instance Show ByteString where
  showsPrec p (BS s) = showsPrec p s
instance Read ByteString where
  readsPrec p s = [(BS x, r) | (x, r) <- readsPrec p s]
instance Semigroup ByteString where
  BS a <> BS b = BS (a ++ b)
instance Monoid ByteString where
  mempty = BS ""
instance IsString ByteString where
  fromString = packChars

-- strict, and truncated to bytes as Char8.pack does
packChars :: String -> ByteString
packChars s = let s' = map (\c -> toEnum (fromEnum c `mod` 256)) s
              in foldr seq () s' `seq` BS s'

c2w :: Char -> Word8
c2w = fromIntegral . fromEnum

w2c :: Word8 -> Char
w2c = toEnum . fromIntegral
