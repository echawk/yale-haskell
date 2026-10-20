import qualified GHC.Foreign as GF
import GHC.IO.Encoding (utf8, latin1, getFileSystemEncoding, textEncodingName)
main = do
  s <- GF.withCStringLen utf8 "naïve ☃" (GF.peekCStringLen utf8)
  n <- GF.withCStringLen utf8 "naïve ☃" (return . snd)
  t <- GF.withCString latin1 "café" (GF.peekCString latin1)
  e <- getFileSystemEncoding
  print (s == "naïve ☃", n, t, textEncodingName e)
