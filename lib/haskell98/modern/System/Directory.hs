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
    XdgDirectory(..), getXdgDirectory, XdgDirectoryList(..), getXdgDirectoryList, getAppUserDataDirectory,
    getUserDocumentsDirectory, exeExtension, findFile, findFiles,
    getFileSize, removePathForcibly, renamePath, pathIsSymbolicLink,
    getSymbolicLinkTarget,
    emptyPermissions, setOwnerReadable, setOwnerWritable, setOwnerExecutable,
    setOwnerSearchable, copyPermissions, copyFileWithMetadata,
    findExecutables, findExecutablesInDirectories, findFileWith,
    findFilesWith, getAccessTime, setAccessTime, setModificationTime
  ) where

import SystemDirectoryBase hiding (getModificationTime)
import DirectoryPrims (primGetModificationTime)
import Data.Time.Clock (UTCTime)
import Data.Time.Clock.POSIX (posixSecondsToUTCTime, utcTimeToPOSIXSeconds)
import PosixPrims (primPosixStat, primStatAtime, primStatMtime, primPosixUtimes)
import System.Environment (lookupEnv)
import Control.Monad (filterM)
import Data.Maybe (catMaybes, fromMaybe)

getModificationTime :: FilePath -> IO UTCTime
getModificationTime name = do
  secs <- primGetModificationTime name
  return (posixSecondsToUTCTime (fromInteger secs))

emptyPermissions :: Permissions
emptyPermissions = Permissions False False False False

setOwnerReadable, setOwnerWritable, setOwnerExecutable, setOwnerSearchable
  :: Bool -> Permissions -> Permissions
setOwnerReadable b (Permissions _ w x s) = Permissions b w x s
setOwnerWritable b (Permissions r _ x s) = Permissions r b x s
setOwnerExecutable b (Permissions r w _ s) = Permissions r w b s
setOwnerSearchable b (Permissions r w x _) = Permissions r w x b

copyPermissions :: FilePath -> FilePath -> IO ()
copyPermissions src dst = getPermissions src >>= setPermissions dst

copyFileWithMetadata :: FilePath -> FilePath -> IO ()
copyFileWithMetadata src dst = do
  copyFile src dst
  copyPermissions src dst
  st <- primPosixStat src True
  primPosixUtimes dst (primStatAtime st) (primStatMtime st)

-- (the executables named, in the directories of $PATH)
findExecutables :: String -> IO [FilePath]
findExecutables name = do
  v <- lookupEnv "PATH"
  findExecutablesInDirectories (splitPath' (fromMaybe "" v)) name
  where
    splitPath' t = case break (== ':') t of
      (a, []) -> [a]
      (a, _ : r) -> a : splitPath' r

findExecutablesInDirectories :: [FilePath] -> String -> IO [FilePath]
findExecutablesInDirectories dirs name = findFilesWith isExec dirs name
  where isExec f = fmap executable (getPermissions f)

findFileWith :: (FilePath -> IO Bool) -> [FilePath] -> String -> IO (Maybe FilePath)
findFileWith ok dirs name = fmap (\fs -> case fs of { f : _ -> Just f; [] -> Nothing })
                                 (findFilesWith ok dirs name)

findFilesWith :: (FilePath -> IO Bool) -> [FilePath] -> String -> IO [FilePath]
findFilesWith ok dirs name = do
  fs <- findFiles dirs name
  filterM ok fs

getAccessTime :: FilePath -> IO UTCTime
getAccessTime p = do
  st <- primPosixStat p True
  return (posixSecondsToUTCTime (fromInteger (primStatAtime st)))

setAccessTime, setModificationTime :: FilePath -> UTCTime -> IO ()
setAccessTime p t = do
  st <- primPosixStat p True
  primPosixUtimes p (floor (utcTimeToPOSIXSeconds t)) (primStatMtime st)
setModificationTime p t = do
  st <- primPosixStat p True
  primPosixUtimes p (primStatAtime st) (floor (utcTimeToPOSIXSeconds t))
