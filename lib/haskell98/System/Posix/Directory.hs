-- System.Posix.Directory (unix): creating and removing directories with
-- POSIX permissions, and the working directory.
module System.Posix.Directory (
    createDirectory, removeDirectory, getWorkingDirectory,
    changeWorkingDirectory,
    DirStream, openDirStream, readDirStream, rewindDirStream, closeDirStream
  ) where

import PosixPrims
import System.Posix.Types
import qualified System.Directory as D
import Data.IORef

createDirectory :: FilePath -> FileMode -> IO ()
createDirectory p m = primPosixMkdir p (fromIntegral m)

removeDirectory :: FilePath -> IO ()
removeDirectory = primPosixRmdir

getWorkingDirectory :: IO FilePath
getWorkingDirectory = D.getCurrentDirectory

changeWorkingDirectory :: FilePath -> IO ()
changeWorkingDirectory = D.setCurrentDirectory

-- A directory's entries, read when it is opened (with "." and "..").
data DirStream = DirStream FilePath (IORef [FilePath])

openDirStream :: FilePath -> IO DirStream
openDirStream p = do
  es <- D.getDirectoryContents p
  r <- newIORef es
  return (DirStream p r)

-- the next entry, or "" at the end
readDirStream :: DirStream -> IO FilePath
readDirStream (DirStream _ r) = do
  es <- readIORef r
  case es of
    [] -> return ""
    (e : rest) -> writeIORef r rest >> return e

rewindDirStream :: DirStream -> IO ()
rewindDirStream (DirStream p r) = D.getDirectoryContents p >>= writeIORef r

closeDirStream :: DirStream -> IO ()
closeDirStream (DirStream _ r) = writeIORef r []
