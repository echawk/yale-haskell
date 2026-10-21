import qualified Data.ByteString.Builder.Scientific as BS
import qualified Data.Text.Lazy.Builder.Scientific as TS
import qualified Data.ByteString.Builder as BB
import qualified Data.ByteString.Lazy.Char8 as L
import Data.Text.Lazy.Builder (toLazyText)
import Data.Scientific (scientific)
main = do
  L.putStrLn (BB.toLazyByteString (BS.scientificBuilder (scientific 15 (-1))))
  print (toLazyText (TS.formatScientificBuilder TS.Fixed (Just 3) (scientific 2 0)))
