import System.IO
import Foreign.Marshal.Alloc
import Foreign.Storable
import Data.Word
import System.Directory (removeFile)

main :: IO ()
main = do
  writeFile "hgetbuf-some.tmp" "abc"
  h <- openBinaryFile "hgetbuf-some.tmp" ReadMode
  allocaBytes 8 $ \p -> do
    n <- hGetBufSome h p 8
    b <- peek p :: IO Word8
    print (n, b)
  hClose h
  removeFile "hgetbuf-some.tmp"
