-- System.Posix.IO's fdReadBuf and fdWriteBuf, through memory at a Ptr
-- (entropy's).
import System.Posix.IO
import System.Posix.Types
import Foreign
import System.Directory (removeFile)

main :: IO ()
main = do
  let path = "posix-fd-buf.tmp"
  fd <- createFile path 0o644
  n <- withArray (map (fromIntegral . fromEnum) "hello") $ \p -> fdWriteBuf fd p 5
  closeFd fd
  fd2 <- openFd path ReadOnly Nothing defaultFileFlags
  s <- allocaBytes 16 $ \p -> do
    m <- fdReadBuf fd2 p 16
    ws <- peekArray (fromIntegral m) p
    return (map (toEnum . fromIntegral) ws :: String)
  closeFd fd2
  removeFile path
  print (n, s)
