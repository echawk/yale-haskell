{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
-- Data.Text.Internal (text 2): a Text shown as UTF-8 in a byte array,
-- Text arr off len.  A Text here is a string of Chars (Data.Text.Rep),
-- so matching Text encodes it into a new array (off 0) and building one
-- decodes the bytes: O(n) each, with the same results.
module Data.Text.Internal (
    Text(Text), text, empty, safe, pack, append, showText
  ) where

import qualified Data.Text as T
import Data.Text (Text, pack, append, empty)
import qualified Data.Text.Array as A
import qualified Data.ByteString.Rep as B
import Data.Text.Encoding (encodeUtf8, decodeUtf8)
import Data.Char (ord)

pattern Text :: A.Array -> Int -> Int -> Text
pattern Text arr off len <- (toUtf8 -> (arr, off, len))
  where Text arr off len = text arr off len

toUtf8 :: Text -> (A.Array, Int, Int)
toUtf8 t =
  let ws = map B.c2w (B.unBS (encodeUtf8 t))
  in (A.fromList ws, 0, length ws)

-- | The Text of the LEN bytes of UTF-8 from OFF.
text :: A.Array -> Int -> Int -> Text
text arr off len = decodeUtf8 (B.bsFromString (map B.w2c (A.toList arr off len)))

-- | A Char a Text may hold (not a surrogate).
safe :: Char -> Char
safe c | ord c >= 0xD800 && ord c <= 0xDFFF = '\xFFFD'
       | otherwise = c

showText :: Text -> String
showText = show
