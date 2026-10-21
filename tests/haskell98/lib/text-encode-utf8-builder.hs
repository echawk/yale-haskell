import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TLE
import qualified Data.ByteString.Builder as BB
import qualified Data.ByteString.Builder.Prim as BP
import qualified Data.ByteString.Lazy as L
main = do
  let esc = BP.condB (== 34) (BP.liftFixedToBounded ((\w -> (92, w)) BP.>$< BP.word8 BP.>*< BP.word8)) (BP.liftFixedToBounded BP.word8)
  print (L.unpack (BB.toLazyByteString (TE.encodeUtf8BuilderEscaped esc (T.pack "a\"é"))))
  print (L.unpack (BB.toLazyByteString (TE.encodeUtf8Builder (T.pack "ok"))))
  print (L.unpack (BB.toLazyByteString (TLE.encodeUtf8Builder (TL.pack "é!") <> TLE.encodeUtf8BuilderEscaped esc (TL.pack "\""))))
