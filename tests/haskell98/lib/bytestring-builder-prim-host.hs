import qualified Data.ByteString.Builder.Prim as P
import Data.ByteString.Builder (toLazyByteString)
import qualified Data.ByteString as S
import qualified Data.ByteString.Lazy as L
main = do
  let run b = print (L.unpack (toLazyByteString b))
  run (P.primFixed P.int16BE (-2) <> P.primFixed P.int32LE (-3) <> P.primFixed P.int64BE 258)
  run (P.primFixed P.intHost (-1) <> P.primFixed P.wordHost 1 <> P.primFixed P.word16Host 258)
  run (P.primMapByteStringBounded (P.liftFixedToBounded P.word8) (S.pack [1,2]) <> P.primMapLazyByteStringBounded (P.liftFixedToBounded P.word8) (L.pack [3]))
