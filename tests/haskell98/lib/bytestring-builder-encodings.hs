import qualified Data.ByteString.Builder as B
import qualified Data.ByteString.Lazy as L
import qualified Data.Text.Lazy as LT
import qualified Data.Text as T
main = do
  print (L.unpack (B.toLazyByteString (B.word16Dec 65535 <> B.word32BE 258 <> B.int16LE (-2))))
  print (L.unpack (B.toLazyByteString (B.word16HexFixed 255 <> B.doubleHexFixed 1.0)))
  print (LT.foldrChunks (\c n -> T.length c + n) 0 (LT.pack "abcd"))
