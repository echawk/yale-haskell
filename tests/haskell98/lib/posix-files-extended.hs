import System.Posix
import System.IO
import Control.Exception (try, IOException)

main :: IO ()
main = do
  (path, h) <- mkstemp "/tmp/yale-posix-test"
  hPutStr h "hello, world"
  hClose h
  st <- getFileStatus path
  print (fileSize st, isRegularFile st, isSocket st, linkCount st, fileID st > 0)
  setFileSize path 5
  readFile path >>= putStrLn
  let new = path ++ ".renamed"
  rename path new
  createSymbolicLink new (path ++ ".lnk")
  readSymbolicLink (path ++ ".lnk") >>= print . (== new)
  lst <- getSymbolicLinkStatus (path ++ ".lnk")
  print (isSymbolicLink lst, statusChangeTime st > 0)
  fileAccess new True True False >>= print
  getPathVar new FileNameLimit >>= print . (> 0)
  old <- setFileCreationMask 18
  m <- setFileCreationMask old
  print m
  t <- epochTime
  print (t > 1700000000)
  removeLink (path ++ ".lnk")
  removeLink new
  r <- try (getFileStatus new) :: IO (Either IOException FileStatus)
  print (either (const "gone") (const "still there") r)
  sid <- getSystemID
  print (not (null (systemName sid)), not (null (machine sid)))
