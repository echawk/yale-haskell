-- System.Directory (the directory package, a subset), for Yale Haskell's
-- Haskell 98 dialect: the Haskell 98 Directory module plus the common
-- later additions.
module System.Directory (
    Permissions, readable, writable, executable, searchable,
    createDirectory, createDirectoryIfMissing, removeDirectory,
    removeDirectoryRecursive, removeFile, renameDirectory, renameFile,
    getDirectoryContents, listDirectory, getCurrentDirectory,
    setCurrentDirectory, withCurrentDirectory, doesFileExist,
    doesDirectoryExist, doesPathExist, getPermissions, setPermissions,
    getModificationTime, getHomeDirectory, getTemporaryDirectory,
    copyFile, findExecutable, makeAbsolute
  ) where

import Directory
import BasePrims

createDirectoryIfMissing :: Bool -> FilePath -> IO ()
createDirectoryIfMissing = primCreateDirectoryIfMissing

removeDirectoryRecursive :: FilePath -> IO ()
removeDirectoryRecursive = primRemoveDirectoryRecursive

listDirectory :: FilePath -> IO [FilePath]
listDirectory d = getDirectoryContents d >>= \fs ->
                  return (filter (\f -> f /= "." && f /= "..") fs)

withCurrentDirectory :: FilePath -> IO a -> IO a
withCurrentDirectory dir action = do
  old <- getCurrentDirectory
  setCurrentDirectory dir
  r <- action `catch` (\e -> setCurrentDirectory old >> ioError e)
  setCurrentDirectory old
  return r

doesPathExist :: FilePath -> IO Bool
doesPathExist p = doesFileExist p >>= \f -> if f then return True else doesDirectoryExist p

getHomeDirectory :: IO FilePath
getHomeDirectory = primHomeDirectory

getTemporaryDirectory :: IO FilePath
getTemporaryDirectory = primTemporaryDirectory

copyFile :: FilePath -> FilePath -> IO ()
copyFile = primCopyFile

findExecutable :: String -> IO (Maybe FilePath)
findExecutable name = primFindExecutable name >>= \p ->
                      return (if null p then Nothing else Just p)

makeAbsolute :: FilePath -> IO FilePath
makeAbsolute p@('/':_) = return p
makeAbsolute p = getCurrentDirectory >>= \d ->
                 return (if null d || last d == '/' then d ++ p else d ++ "/" ++ p)
