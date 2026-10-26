{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
-- Data.Text.Lazy.Internal (text): a lazy Text's chunks.  Here a lazy Text
-- is one strict Text (Data.Text.Lazy), so it has at most one, nonempty,
-- chunk (attoparsec's Data.Attoparsec.Text.Lazy matches Empty and Chunk).
module Data.Text.Lazy.Internal (
    Text(Empty, Chunk), pattern Empty, pattern Chunk, chunk, empty,
    foldrChunks, foldlChunks, defaultChunkSize, smallChunkSize, chunkOverhead
  ) where

import qualified Data.Text as S
import Data.Text.Lazy (Text, empty, fromStrict, toChunks, foldrChunks, foldlChunks)
import qualified Data.Text.Lazy as L

pattern Empty :: Text
pattern Empty <- (L.null -> True)
  where Empty = L.empty

pattern Chunk :: S.Text -> Text -> Text
pattern Chunk c rest <- (firstChunk -> Just (c, rest))
  where Chunk c rest = L.append (fromStrict c) rest

{-# COMPLETE Empty, Chunk #-}

firstChunk :: Text -> Maybe (S.Text, Text)
firstChunk t = case toChunks t of
  [] -> Nothing
  cs -> Just (S.concat cs, L.empty)

-- | A chunk, unless it is empty, before a lazy Text.
chunk :: S.Text -> Text -> Text
chunk c rest = if S.null c then rest else Chunk c rest

defaultChunkSize, smallChunkSize, chunkOverhead :: Int
defaultChunkSize = 16384 - chunkOverhead
smallChunkSize = 128 - chunkOverhead
chunkOverhead = 16
