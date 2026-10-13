-- System.Posix.Files (unix), a subset: file status, modes, times and
-- links (primitives over the host's POSIX calls, src/base/posix-runtime.lisp).
module System.Posix.Files (
    FileStatus, getFileStatus, getSymbolicLinkStatus, getFdStatus,
    fileMode, fileSize, modificationTime, accessTime,
    isRegularFile, isDirectory, isSymbolicLink, isNamedPipe,
    setFileMode, setFileTimes, touchFile, createLink, createSymbolicLink,
    fileExist,
    nullFileMode, ownerReadMode, ownerWriteMode, ownerExecuteMode,
    ownerModes, groupReadMode, groupWriteMode, groupExecuteMode, groupModes,
    otherReadMode, otherWriteMode, otherExecuteMode, otherModes,
    stdFileMode, accessModes, unionFileModes, intersectFileModes
  ) where

import PosixPrims
import System.Posix.Types
import Data.Bits ((.|.), (.&.))
import System.Directory (doesFileExist, doesDirectoryExist)

newtype FileStatus = FileStatus FileStatusObj

getFileStatus, getSymbolicLinkStatus :: FilePath -> IO FileStatus
getFileStatus p = fmap FileStatus (primPosixStat p True)
getSymbolicLinkStatus p = fmap FileStatus (primPosixStat p False)

getFdStatus :: Fd -> IO FileStatus
getFdStatus (Fd n) = fmap FileStatus (primPosixFstat (fromIntegral n))

fileMode :: FileStatus -> FileMode
fileMode (FileStatus s) = fromIntegral (primStatMode s)

fileSize :: FileStatus -> FileOffset
fileSize (FileStatus s) = fromInteger (primStatSize s)

modificationTime, accessTime :: FileStatus -> EpochTime
modificationTime (FileStatus s) = fromInteger (primStatMtime s)
accessTime (FileStatus s) = fromInteger (primStatAtime s)

fileType :: FileStatus -> Int
fileType (FileStatus s) = primModeFileType (primStatMode s)

isRegularFile, isDirectory, isSymbolicLink, isNamedPipe :: FileStatus -> Bool
isRegularFile st = fileType st == 0
isDirectory st = fileType st == 1
isSymbolicLink st = fileType st == 2
isNamedPipe st = fileType st == 3

setFileMode :: FilePath -> FileMode -> IO ()
setFileMode p m = primPosixChmod p (fromIntegral m)

setFileTimes :: FilePath -> EpochTime -> EpochTime -> IO ()
setFileTimes p a m = primPosixUtimes p (toInteger a) (toInteger m)

touchFile :: FilePath -> IO ()
touchFile p = do
  st <- getFileStatus p
  setFileTimes p (accessTime st) (accessTime st)

createLink, createSymbolicLink :: FilePath -> FilePath -> IO ()
createLink = primPosixLink
createSymbolicLink = primPosixSymlink

fileExist :: FilePath -> IO Bool
fileExist p = do
  f <- doesFileExist p
  if f then return True else doesDirectoryExist p

nullFileMode, ownerReadMode, ownerWriteMode, ownerExecuteMode, ownerModes,
  groupReadMode, groupWriteMode, groupExecuteMode, groupModes,
  otherReadMode, otherWriteMode, otherExecuteMode, otherModes,
  stdFileMode, accessModes :: FileMode
nullFileMode = 0
ownerReadMode = 256
ownerWriteMode = 128
ownerExecuteMode = 64
ownerModes = 448
groupReadMode = 32
groupWriteMode = 16
groupExecuteMode = 8
groupModes = 56
otherReadMode = 4
otherWriteMode = 2
otherExecuteMode = 1
otherModes = 7
stdFileMode = 438
accessModes = 511

unionFileModes, intersectFileModes :: FileMode -> FileMode -> FileMode
unionFileModes a b = a .|. b
intersectFileModes a b = a .&. b
