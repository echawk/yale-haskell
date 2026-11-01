import System.IO.Error
import System.Directory

main :: IO ()
main = do
  r <- tryIOError (readFile "/nonexistent/file")
  case r of
    Left e -> print (isDoesNotExistErrorType (ioeGetErrorType e), isFullErrorType (ioeGetErrorType e))
    Right _ -> putStrLn "?"
  ds <- getXdgDirectoryList XdgDataDirs
  print (not (null ds))
