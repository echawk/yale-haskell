import qualified Data.ByteString.Lazy.Char8 as L
import qualified Data.ByteString.Char8 as B
import System.IO
main = do
  (p, h) <- openTempFile "/tmp" "yale-bs"
  hPutStr h "hello"
  hClose h
  h2 <- openFile p ReadMode
  s <- B.hGetNonBlocking h2 3
  t <- L.hGetSome h2 5
  print (s, t)
