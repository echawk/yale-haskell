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
    copyFile, findExecutable, makeAbsolute,
    canonicalizePath, makeRelativeToCurrentDirectory,
    XdgDirectory(..), getXdgDirectory, getAppUserDataDirectory,
    getUserDocumentsDirectory, exeExtension, findFile, findFiles,
    getFileSize, removePathForcibly, renamePath, pathIsSymbolicLink,
    getSymbolicLinkTarget
  ) where

import Directory
import BasePrims
import PosixPrims (primPosixStat, primStatMode, primStatSize,
                   primModeFileType, primPosixReadlink, primPosixRename)
import System.Environment (lookupEnv)
import Monad (filterM)

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

-- | The absolute path with ., .. and symbolic links resolved; a part that
-- does not exist is kept as it is, as directory's does.
canonicalizePath :: FilePath -> IO FilePath
canonicalizePath p = do
  a <- makeAbsolute p
  r <- resolve (40 :: Int) [] (splitDirs a)
  return ('/' : joinDirs (reverse r))
  where
    -- the parts so far, last first
    resolve _ done [] = return done
    resolve n done (c : rest)
      | c == "." || null c = resolve n done rest
      | c == ".." = resolve n (drop 1 done) rest
      | otherwise = do
          let path = '/' : joinDirs (reverse (c : done))
          link <- pathIsSymbolicLink path `catch` (\_ -> return False)
          if link && n > 0
            then do
              target <- getSymbolicLinkTarget path
              let start = if take 1 target == "/" then [] else done
              resolve (n - 1) start (splitDirs target ++ rest)
            else resolve n (c : done) rest

splitDirs :: FilePath -> [String]
splitDirs s = case break (== '/') s of
  (a, []) -> [a]
  (a, _ : b) -> a : splitDirs b

joinDirs :: [String] -> FilePath
joinDirs [] = ""
joinDirs [d] = d
joinDirs (d : ds) = d ++ "/" ++ joinDirs ds

-- | The path relative to the current directory when it is below it.
makeRelativeToCurrentDirectory :: FilePath -> IO FilePath
makeRelativeToCurrentDirectory p = do
  cwd <- getCurrentDirectory
  a <- makeAbsolute p
  let base = if null cwd || last cwd == '/' then cwd else cwd ++ "/"
  return (if take (length base) a == base && length a > length base
            then drop (length base) a
            else if a == cwd then "." else p)

data XdgDirectory = XdgData | XdgConfig | XdgCache | XdgState
  deriving (Eq, Ord, Read, Show)

-- | $XDG_DATA_HOME (and the others), or its default under the home
-- directory, with the path given.
getXdgDirectory :: XdgDirectory -> FilePath -> IO FilePath
getXdgDirectory d path = do
  let (var, def) = case d of
        XdgData -> ("XDG_DATA_HOME", ".local/share")
        XdgConfig -> ("XDG_CONFIG_HOME", ".config")
        XdgCache -> ("XDG_CACHE_HOME", ".cache")
        XdgState -> ("XDG_STATE_HOME", ".local/state")
  v <- lookupEnv var
  base <- case v of
    Just b | take 1 b == "/" -> return b
    _ -> fmap (++ ("/" ++ def)) getHomeDirectory
  return (if null path then base else base ++ "/" ++ path)

getAppUserDataDirectory :: String -> IO FilePath
getAppUserDataDirectory app = fmap (++ ("/." ++ app)) getHomeDirectory

getUserDocumentsDirectory :: IO FilePath
getUserDocumentsDirectory = getHomeDirectory

exeExtension :: String
exeExtension = ""

findFile :: [FilePath] -> String -> IO (Maybe FilePath)
findFile dirs name = fmap (\fs -> case fs of { f : _ -> Just f; [] -> Nothing })
                          (findFiles dirs name)

findFiles :: [FilePath] -> String -> IO [FilePath]
findFiles dirs name =
  filterM doesFileExist [ if null d then name else d ++ "/" ++ name | d <- dirs ]

getFileSize :: FilePath -> IO Integer
getFileSize p = fmap primStatSize (primPosixStat p True)

-- | Removes a file or a directory and what it holds; nothing when there
-- is nothing there.
removePathForcibly :: FilePath -> IO ()
removePathForcibly p = do
  link <- pathIsSymbolicLink p `catch` (\_ -> return False)
  dir <- doesDirectoryExist p
  file <- doesFileExist p
  if dir && not link then removeDirectoryRecursive p
    else if file || link then removeFile p
    else return ()

renamePath :: FilePath -> FilePath -> IO ()
renamePath = primPosixRename

pathIsSymbolicLink :: FilePath -> IO Bool
pathIsSymbolicLink p = fmap (\st -> primModeFileType (primStatMode st) == 2)
                            (primPosixStat p False)

getSymbolicLinkTarget :: FilePath -> IO FilePath
getSymbolicLinkTarget = primPosixReadlink
