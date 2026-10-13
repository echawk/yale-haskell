{-# OPTIONS -w #-}
{- Workaround.hs

What darcs 1.0.9's configure writes for a system with POSIX signals and
files, createDirectoryIfMissing, a working renameFile and bracketOnError
(aclocal.m4's WORKAROUND_* macros), for Yale Haskell
(tools/conformance/darcs.py).  openFd is the fd-to-Handle function of
GHC 6's GHC.Handle, here System.Posix.IO's fdToHandle.
-}

module Workaround(
           openFd,
           installHandler, Handler(..), Signal,
           sigINT, sigHUP, sigABRT, sigALRM, sigTERM, sigPIPE,
           getCurrentDirectory,
           createLink,
           createDirectoryIfMissing,
           renameFile,
           bracketOnError,
           fileMode, getFileStatus, setFileMode,
           isExecutable, setExecutable,
 ) where

import System.Posix.Signals (installHandler, Handler(..), Signal,
                             sigINT, sigHUP, sigABRT, sigALRM, sigTERM, sigPIPE)
import System.Directory (getCurrentDirectory, createDirectoryIfMissing, renameFile)
import System.Posix.Files (createLink, fileMode, getFileStatus, setFileMode,
                           unionFileModes, intersectFileModes, nullFileMode,
                           ownerReadMode, ownerWriteMode, ownerExecuteMode,
                           groupReadMode, groupWriteMode, groupExecuteMode,
                           otherReadMode, otherWriteMode, otherExecuteMode)
import System.Posix.Types (Fd(..))
import System.Posix.IO (fdToHandle)
import Control.Exception (bracketOnError)
import System.IO (Handle, IOMode)

openFd :: Int -> Maybe () -> FilePath -> IOMode -> Bool -> Bool -> IO Handle
openFd fd _ _ _ _ _ = fdToHandle (Fd (fromIntegral fd))

isExecutable :: FilePath -> IO Bool
isExecutable f = do st <- getFileStatus f
                    let x = fileMode st
                            `intersectFileModes` ownerExecuteMode
                    return $ x /= nullFileMode

setExecutable :: FilePath -> Bool -> IO ()
setExecutable f ex =
  do st <- getFileStatus f
     let rw = fileMode st `intersectFileModes`
              (ownerReadMode `unionFileModes` ownerWriteMode `unionFileModes`
               groupReadMode `unionFileModes` groupWriteMode `unionFileModes`
               otherReadMode `unionFileModes` otherWriteMode)
         total = if ex then rw `unionFileModes` ownerExecuteMode
                               `unionFileModes` groupExecuteMode
                               `unionFileModes` otherExecuteMode
                       else rw
     setFileMode f total
