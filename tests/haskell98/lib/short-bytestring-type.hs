-- ShortByteString is a type of its own (digest's CRC32C has instances for
-- it and ByteString).
{-# LANGUAGE MagicHash, PatternSynonyms #-}
import qualified Data.ByteString as B
import qualified Data.ByteString.Short as S
import Data.ByteString.Short.Internal (pattern SBS)
import GHC.Exts (sizeofByteArray#)
class Size a where size :: a -> Int
instance Size B.ByteString where size = B.length
instance Size S.ShortByteString where size s = 100 + S.length s
main :: IO ()
main = do
  let s = S.pack [1, 2, 3]
  print (size (B.pack [1, 2]), size s, S.unpack (s <> s), S.fromShort s)
  case s of SBS a -> print (sizeofByteArray# a)
