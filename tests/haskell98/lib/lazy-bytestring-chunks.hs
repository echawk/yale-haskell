{-# LANGUAGE PatternSynonyms #-}
import qualified Data.ByteString.Char8 as S
import qualified Data.ByteString.Lazy.Internal as L
import qualified Data.ByteString.Lazy.Char8 as LC

chunks :: L.ByteString -> [S.ByteString]
chunks L.Empty = []
chunks (L.Chunk c rest) = c : chunks rest

main :: IO ()
main = do
  print (chunks (LC.pack "hello"), chunks (LC.pack ""))
  print (L.Chunk (S.pack "ab") (L.Chunk (S.pack "cd") L.Empty))
  print (L.chunk S.empty L.Empty == LC.pack "")
