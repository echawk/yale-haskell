import Data.Text.Lazy.Builder (toLazyText)
import Data.Text.Lazy.Builder.Int (decimal, hexadecimal)
import Data.Text.Lazy.Builder.RealFloat (realFloat, formatRealFloat, FPFormat(..))
main = do
  print (toLazyText (decimal (-42 :: Int)), toLazyText (hexadecimal (255 :: Integer)))
  print (toLazyText (realFloat (1.5 :: Double)), toLazyText (formatRealFloat Fixed (Just 2) (3.14159 :: Double)))
