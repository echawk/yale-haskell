-- Data.Text.Unsafe (text 2): what does not check its arguments.
module Data.Text.Unsafe (
    unsafeDupablePerformIO, inlinePerformIO, inlineInterleaveST,
    unsafeHead, unsafeTail, lengthWord8, takeWord8, dropWord8,
    Iter(Iter), iter
  ) where

import qualified Data.Text as T
import Data.Text (Text)
import qualified Data.ByteString.Rep as B
import Data.Text.Encoding (encodeUtf8, decodeUtf8)
import System.IO.Unsafe (unsafeDupablePerformIO)
import Control.Monad.ST (ST)
import Control.Monad.ST.Unsafe (unsafeInterleaveST)

inlinePerformIO :: IO a -> a
inlinePerformIO = unsafeDupablePerformIO

inlineInterleaveST :: ST s a -> ST s a
inlineInterleaveST = unsafeInterleaveST

unsafeHead :: Text -> Char
unsafeHead = T.head

unsafeTail :: Text -> Text
unsafeTail = T.tail

utf8 :: Text -> [Char]
utf8 = B.unBS . encodeUtf8

fromUtf8 :: [Char] -> Text
fromUtf8 = decodeUtf8 . B.bsFromString

-- | The number of bytes of its UTF-8.
lengthWord8 :: Text -> Int
lengthWord8 = length . utf8

takeWord8 :: Int -> Text -> Text
takeWord8 n = fromUtf8 . take n . utf8

dropWord8 :: Int -> Text -> Text
dropWord8 n = fromUtf8 . drop n . utf8

-- | A Char and the number of bytes its UTF-8 takes.
data Iter = Iter {-# UNPACK #-} !Char {-# UNPACK #-} !Int

-- | The Char at byte I and its length.
iter :: Text -> Int -> Iter
iter t i = case T.uncons (dropWord8 i t) of
  Just (c, _) -> Iter c (length (B.unBS (encodeUtf8 (T.singleton c))))
  Nothing -> error "Data.Text.Unsafe.iter: past the end"
