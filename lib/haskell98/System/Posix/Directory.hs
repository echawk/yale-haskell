-- System.Posix.Directory (unix): creating and removing directories with
-- POSIX permissions, and the working directory.
module System.Posix.Directory (
    createDirectory, removeDirectory, getWorkingDirectory,
    changeWorkingDirectory
  ) where

import PosixPrims
import System.Posix.Types
import qualified System.Directory as D

createDirectory :: FilePath -> FileMode -> IO ()
createDirectory p m = primPosixMkdir p (fromIntegral m)

removeDirectory :: FilePath -> IO ()
removeDirectory = primPosixRmdir

getWorkingDirectory :: IO FilePath
getWorkingDirectory = D.getCurrentDirectory

changeWorkingDirectory :: FilePath -> IO ()
changeWorkingDirectory = D.setCurrentDirectory
