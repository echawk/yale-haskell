-- System.IO.Error: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module IO
-- and the Prelude names the 2010 Report lists, plus what 2010 added.
module System.IO.Error (
    userError, ioError, catchIOError, tryIOError,
    isAlreadyExistsError, isDoesNotExistError, isAlreadyInUseError,
    isFullError, isEOFError, isIllegalOperation, isPermissionError,
    isUserError, ioeGetErrorString, ioeGetHandle, ioeGetFileName
  ) where

import IO

catchIOError :: IO a -> (IOError -> IO a) -> IO a
catchIOError = catch

tryIOError :: IO a -> IO (Either IOError a)
tryIOError = try
