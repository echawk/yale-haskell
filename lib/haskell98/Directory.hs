-- Directory.hs -- the Haskell 98 Directory library
--
-- Interface as in the Haskell 98 Library Report, chapter 12.  Errors
-- are IOErrors (see IO.hs): isDoesNotExistError, isAlreadyExistsError,
-- isPermissionError and isIllegalOperation as the Report describes.
-- getDirectoryContents includes "." and ".." and is not sorted.
--
-- Permissions apply to the current user.  setPermissions sets the
-- owner's read, write and execute bits (execute from executable or
-- searchable) and leaves the group and other bits alone.
--
-- Stopgaps until the compiler has records and the Prelude is H98:
--   * Permissions is a positional constructor
--     (Permissions readable writable executable searchable) with
--     hand-written field selectors; record syntax is not available.
--   * It derives Text instead of Read/Show.
--   * FilePath is not in the Prelude yet; names are Strings.

module Directory (
    Permissions(Permissions), readable, writable, executable, searchable,
    createDirectory, removeDirectory, removeFile,
    renameDirectory, renameFile, getDirectoryContents,
    getCurrentDirectory, setCurrentDirectory,
    doesFileExist, doesDirectoryExist,
    getPermissions, setPermissions,
    getModificationTime ) where

import Time
import DirectoryPrims

data Permissions = Permissions Bool Bool Bool Bool
                   deriving (Eq, Ord, Text)

readable, writable, executable, searchable :: Permissions -> Bool
readable   (Permissions x _ _ _) = x
writable   (Permissions _ x _ _) = x
executable (Permissions _ _ x _) = x
searchable (Permissions _ _ _ x) = x

createDirectory         :: String -> IO ()
createDirectory         =  primCreateDirectory

removeDirectory         :: String -> IO ()
removeDirectory         =  primRemoveDirectory

removeFile              :: String -> IO ()
removeFile              =  primRemoveFile

renameDirectory         :: String -> String -> IO ()
renameDirectory         =  primRenameDirectory

renameFile              :: String -> String -> IO ()
renameFile              =  primRenameFile

getDirectoryContents    :: String -> IO [String]
getDirectoryContents    =  primGetDirectoryContents

getCurrentDirectory     :: IO String
getCurrentDirectory     =  primGetCurrentDirectory

setCurrentDirectory     :: String -> IO ()
setCurrentDirectory     =  primSetCurrentDirectory

doesFileExist           :: String -> IO Bool
doesFileExist           =  primDoesFileExist

doesDirectoryExist      :: String -> IO Bool
doesDirectoryExist      =  primDoesDirectoryExist

getPermissions          :: String -> IO Permissions
getPermissions name     =  primGetPermissions name `thenIO` \[r, w, x, s] ->
                           returnIO (Permissions r w x s)

setPermissions          :: String -> Permissions -> IO ()
setPermissions name (Permissions r w x s) = primSetPermissions name r w x s

getModificationTime     :: String -> IO ClockTime
getModificationTime name =
  primGetModificationTime name `thenIO` \secs ->
  returnIO (addToClockTime (TimeDiff 0 0 0 0 0 (fromInteger secs) 0) epoch)

epoch :: ClockTime
epoch = toClockTime (CalendarTime 1970 January 1 0 0 0 0 Thursday 0 "UTC" 0 False)
