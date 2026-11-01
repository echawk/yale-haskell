import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
main :: IO ()
main = do
  print (T.foldl1' max (T.pack "abc"))
  print (TL.foldr1' min (TL.pack "abc"))
