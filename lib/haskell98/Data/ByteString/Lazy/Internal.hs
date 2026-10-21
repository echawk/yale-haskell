-- Data.ByteString.Lazy.Internal (bytestring): the lazy ByteString, its
-- own type as in bytestring, over the strict one (Yale Haskell reads a
-- file in one piece either way).  Data.ByteString.Lazy and
-- Data.ByteString.Lazy.Char8 are generated over it
-- (tools/gen/lazy-bytestring.py).
{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
module Data.ByteString.Lazy.Internal (
    ByteString(LBS), pattern Empty, pattern Chunk, chunk,
    defaultChunkSize, smallChunkSize, chunkOverhead
  ) where

import qualified Data.ByteString.Rep as S
import PreludeModern (Semigroup((<>)), Monoid(mempty))
import Data.String (IsString(fromString))
import Control.DeepSeq (NFData(rnf))

newtype ByteString = LBS S.ByteString

instance Eq ByteString where
  LBS a == LBS b = a == b
instance Ord ByteString where
  compare (LBS a) (LBS b) = compare a b
instance Show ByteString where
  showsPrec p (LBS b) = showsPrec p b
instance Read ByteString where
  readsPrec p s = [(LBS b, r) | (b, r) <- readsPrec p s]
instance Semigroup ByteString where
  LBS a <> LBS b = LBS (a <> b)
instance Monoid ByteString where
  mempty = LBS mempty
instance IsString ByteString where
  fromString s = LBS (fromString s)

instance NFData ByteString where
  rnf (LBS b) = rnf b

-- bytestring's chunk constructors: here at most one, nonempty, chunk.
pattern Empty :: ByteString
pattern Empty <- (isEmpty -> True)
  where Empty = LBS mempty

pattern Chunk :: S.ByteString -> ByteString -> ByteString
pattern Chunk c rest <- (firstChunk -> Just (c, rest))
  where Chunk c (LBS b) = LBS (c <> b)

{-# COMPLETE Empty, Chunk #-}

isEmpty :: ByteString -> Bool
isEmpty (LBS b) = b == mempty

firstChunk :: ByteString -> Maybe (S.ByteString, ByteString)
firstChunk (LBS b)
  | b == mempty = Nothing
  | otherwise = Just (b, LBS mempty)

-- | A chunk, unless it is empty, before a lazy ByteString.
chunk :: S.ByteString -> ByteString -> ByteString
chunk c rest = Chunk c rest

-- bytestring's chunk sizes (a chunk is one strict ByteString here)
defaultChunkSize, smallChunkSize, chunkOverhead :: Int
defaultChunkSize = 32 * 1024 - chunkOverhead
smallChunkSize = 4 * 1024 - chunkOverhead
chunkOverhead = 16
