-- System.IO.Error: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module IO
-- and the Prelude names the 2010 Report lists, plus what 2010 added.
-- catchIOError, tryIOError and ioeGetErrorType are base's, not the Report's.
module System.IO.Error (
    IOError, userError, mkIOError, annotateIOError,
    isAlreadyExistsError, isDoesNotExistError, isAlreadyInUseError,
    isFullError, isEOFError, isIllegalOperation, isPermissionError,
    isUserError, ioeGetErrorString, ioeGetHandle, ioeGetFileName,
    IOErrorType, alreadyExistsErrorType, doesNotExistErrorType,
    alreadyInUseErrorType, fullErrorType, eofErrorType,
    illegalOperationErrorType, permissionErrorType, userErrorType,
    ioeGetErrorType,
    ioError, catch, try, catchIOError, tryIOError
  ) where

import IO
import IOBase(Handle(..))
import IOPrims
import PreludeIO (IOError(..), catch)

-- The kinds of IOError: the numbers are those of *io-error-kinds* in
-- src/runtime/io-errors.mumble.
data IOErrorType = IOErrorType Int

instance Eq IOErrorType where
  IOErrorType a == IOErrorType b = a == b

instance Show IOErrorType where
  showsPrec _ (IOErrorType k) = showString (kindNames !! k)
    where kindNames = ["failed", "already exists", "does not exist",
                       "resource busy", "resource exhausted", "end of file",
                       "illegal operation", "permission denied", "user error"]

alreadyExistsErrorType, doesNotExistErrorType, alreadyInUseErrorType,
  fullErrorType, eofErrorType, illegalOperationErrorType,
  permissionErrorType, userErrorType :: IOErrorType
alreadyExistsErrorType    = IOErrorType 1
doesNotExistErrorType     = IOErrorType 2
alreadyInUseErrorType     = IOErrorType 3
fullErrorType             = IOErrorType 4
eofErrorType              = IOErrorType 5
illegalOperationErrorType = IOErrorType 6
permissionErrorType       = IOErrorType 7
userErrorType             = IOErrorType 8

ioeGetErrorType :: IOError -> IOErrorType
ioeGetErrorType (IOError e) = IOErrorType (primIOErrorKind e)

-- An IOError of the given type, location, handle and file name.
mkIOError :: IOErrorType -> String -> Maybe Handle -> Maybe FilePath -> IOError
mkIOError (IOErrorType k) loc mh mpath =
  IOError (primMkIOError k loc (isJustH mh) (handleOf mh)
                         (isJustP mpath) (pathOf mpath))

-- Adds a location (prefixed to the error's own) and, where the error has
-- none, a handle and file name.
annotateIOError :: IOError -> String -> Maybe Handle -> Maybe FilePath -> IOError
annotateIOError (IOError e) loc mh mpath =
  IOError (primAnnotateIOError e loc (isJustH mh) (handleOf mh)
                               (isJustP mpath) (pathOf mpath))

isJustH :: Maybe Handle -> Bool
isJustH (Just _) = True
isJustH Nothing  = False

handleOf :: Maybe Handle -> HandleObj
handleOf (Just (Handle h)) = h
handleOf Nothing           = primStdin   -- unused: the flag is False

isJustP :: Maybe FilePath -> Bool
isJustP (Just _) = True
isJustP Nothing  = False

pathOf :: Maybe FilePath -> String
pathOf (Just p) = p
pathOf Nothing  = ""

catchIOError :: IO a -> (IOError -> IO a) -> IO a
catchIOError = catch

tryIOError :: IO a -> IO (Either IOError a)
tryIOError = try
