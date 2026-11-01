import qualified Data.ByteString as S
import qualified Data.ByteString.Char8 as C

main :: IO ()
main = do
  print (S.foldl1' max (S.pack [3, 9, 2]))
  print (C.foldr1' min (C.pack "hello"))
