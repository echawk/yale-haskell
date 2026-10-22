-- System.Directory as in the current directory package, for
-- --modern-prelude (modules under lib/haskell98/modern/ are found before
-- the library's own): getModificationTime gives a UTCTime, not
-- old-time's ClockTime.
module System.Directory (
    Permissions, readable, writable, executable, searchable,
    createDirectory, createDirectoryIfMissing, removeDirectory,
    removeDirectoryRecursive, removeFile, renameDirectory, renameFile,
    getDirectoryContents, listDirectory, getCurrentDirectory,
    setCurrentDirectory, withCurrentDirectory, doesFileExist,
    doesDirectoryExist, doesPathExist, getPermissions, setPermissions,
    getModificationTime, getHomeDirectory, getTemporaryDirectory,
    copyFile, findExecutable, makeAbsolute,
    canonicalizePath, makeRelativeToCurrentDirectory,
    XdgDirectory(..), getXdgDirectory, getAppUserDataDirectory,
    getUserDocumentsDirectory, exeExtension, findFile, findFiles,
    getFileSize, removePathForcibly, renamePath, pathIsSymbolicLink,
    getSymbolicLinkTarget
  ) where

import SystemDirectoryBase hiding (getModificationTime)
import DirectoryPrims (primGetModificationTime)
import Data.Time.Clock (UTCTime)
import Data.Time.Clock.POSIX (posixSecondsToUTCTime)

getModificationTime :: FilePath -> IO UTCTime
getModificationTime name = do
  secs <- primGetModificationTime name
  return (posixSecondsToUTCTime (fromInteger secs))
