import qualified Data.ByteString.Builder as B
import qualified Data.ByteString.Lazy.Char8 as L
import qualified Data.ByteString.Builder.Prim as BP
import Data.ByteString.Builder.Prim ((>$<), (>*<))
import Data.Char (ord)
main = do
  let esc = BP.condB (== '"') (BP.liftFixedToBounded ((\c -> ('\\', c)) >$< BP.char7 >*< BP.char7)) BP.charUtf8
      hex = fromIntegral . ord >$< BP.word16HexFixed
  L.putStrLn (B.toLazyByteString (BP.primMapListBounded esc "say \"hi\"" <> BP.primFixed hex 'A' <> BP.primBounded BP.emptyB 'x'))
