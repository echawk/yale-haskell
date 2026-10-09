-- Haskell 2010 System.IO.Error: mkIOError, annotateIOError, IOErrorType,
-- and the System.IO additions hTell, hShow, hIsTerminalDevice.
module Main where

import System.IO
import System.IO.Error
import System.Directory (removeFile)

main :: IO ()
main = do
  let e = mkIOError doesNotExistErrorType "myOp" Nothing (Just "/no/such")
  print (isDoesNotExistError e, ioeGetFileName e, ioeGetErrorType e == doesNotExistErrorType)
  let e2 = annotateIOError (userError "boom") "outer" Nothing (Just "f.txt")
  print (isUserError e2, ioeGetErrorString e2, ioeGetFileName e2)
  r <- try (ioError (mkIOError eofErrorType "reader" (Just stdin) Nothing))
  case r of
    Left err -> print (isEOFError err, fmap (== stdin) (ioeGetHandle err))
    Right () -> putStrLn "no error"
  print (map show [alreadyExistsErrorType, fullErrorType, permissionErrorType])
  (path, h) <- openTempFile "/tmp" "yale-test.txt"
  hPutStr h "hello"
  n <- hTell h
  hSetFileSize h 2
  sz <- hFileSize h
  hClose h
  removeFile path
  print (n, sz)
  tty <- hIsTerminalDevice h
  echo <- hGetEcho h
  print (tty, echo)
