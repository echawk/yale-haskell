-- System.Posix.Files (unix): file status, modes, times, links, owners,
-- sizes and path variables (primitives over the host's POSIX calls,
-- src/base/posix-runtime.lisp).  Times have whole seconds (the HiRes
-- ones too).
module System.Posix.Files (
    FileStatus, getFileStatus, getSymbolicLinkStatus, getFdStatus,
    deviceID, fileID, fileMode, linkCount, fileOwner, fileGroup,
    specialDeviceID, fileSize, modificationTime, accessTime,
    statusChangeTime, accessTimeHiRes, modificationTimeHiRes,
    statusChangeTimeHiRes,
    isRegularFile, isDirectory, isSymbolicLink, isNamedPipe,
    isBlockDevice, isCharacterDevice, isSocket,
    setFileMode, setFdMode, setFileCreationMask, fileAccess,
    setFileTimes, touchFile, createLink, createSymbolicLink,
    readSymbolicLink, removeLink, rename, createNamedPipe, createDevice,
    setOwnerAndGroup, setFdOwnerAndGroup, setSymbolicLinkOwnerAndGroup,
    setFileSize, setFdSize, fileExist,
    PathVar(..), getPathVar, getFdPathVar,
    nullFileMode, ownerReadMode, ownerWriteMode, ownerExecuteMode,
    ownerModes, groupReadMode, groupWriteMode, groupExecuteMode, groupModes,
    otherReadMode, otherWriteMode, otherExecuteMode, otherModes,
    setUserIDMode, setGroupIDMode,
    stdFileMode, accessModes, unionFileModes, intersectFileModes
  ) where

import PosixPrims
import System.Posix.Types
import Data.Bits ((.|.), (.&.))
import System.Directory (doesFileExist, doesDirectoryExist)
import Data.Time.Clock.POSIX (POSIXTime)

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

deviceID, specialDeviceID :: FileStatus -> DeviceID
deviceID (FileStatus s) = fromInteger (primStatField s 0)
specialDeviceID (FileStatus s) = fromInteger (primStatField s 5)

fileID :: FileStatus -> FileID
fileID (FileStatus s) = fromInteger (primStatField s 1)

linkCount :: FileStatus -> LinkCount
linkCount (FileStatus s) = fromInteger (primStatField s 2)

fileOwner :: FileStatus -> UserID
fileOwner (FileStatus s) = fromInteger (primStatField s 3)

fileGroup :: FileStatus -> GroupID
fileGroup (FileStatus s) = fromInteger (primStatField s 4)

statusChangeTime :: FileStatus -> EpochTime
statusChangeTime (FileStatus s) = fromInteger (primStatField s 6)

accessTimeHiRes, modificationTimeHiRes, statusChangeTimeHiRes
  :: FileStatus -> POSIXTime
accessTimeHiRes = realToFrac . accessTime
modificationTimeHiRes = realToFrac . modificationTime
statusChangeTimeHiRes = realToFrac . statusChangeTime

fileType :: FileStatus -> Int
fileType (FileStatus s) = primModeFileType (primStatMode s)

isRegularFile, isDirectory, isSymbolicLink, isNamedPipe :: FileStatus -> Bool
isRegularFile st = fileType st == 0
isDirectory st = fileType st == 1
isSymbolicLink st = fileType st == 2
isNamedPipe st = fileType st == 3

isBlockDevice, isCharacterDevice, isSocket :: FileStatus -> Bool
isBlockDevice st = fileType st == 5
isCharacterDevice st = fileType st == 6
isSocket st = fileType st == 7

setFileMode :: FilePath -> FileMode -> IO ()
setFileMode p m = primPosixChmod p (fromIntegral m)

setFdMode :: Fd -> FileMode -> IO ()
setFdMode (Fd n) m = primPosixFchmod (fromIntegral n) (fromIntegral m)

-- | Sets the process's mask, returning the old one.
setFileCreationMask :: FileMode -> IO FileMode
setFileCreationMask m = fmap fromIntegral (primPosixUmask (fromIntegral m))

-- | Whether the file can be read, written and executed, as asked.
fileAccess :: FilePath -> Bool -> Bool -> Bool -> IO Bool
fileAccess = primPosixAccess

readSymbolicLink :: FilePath -> IO FilePath
readSymbolicLink = primPosixReadlink

removeLink :: FilePath -> IO ()
removeLink = primPosixUnlink

rename :: FilePath -> FilePath -> IO ()
rename = primPosixRename

createNamedPipe :: FilePath -> FileMode -> IO ()
createNamedPipe p m = primPosixMkfifo p (fromIntegral m)

createDevice :: FilePath -> FileMode -> DeviceID -> IO ()
createDevice p m d = primPosixMknod p (fromIntegral m) (toInteger d)

setOwnerAndGroup, setSymbolicLinkOwnerAndGroup
  :: FilePath -> UserID -> GroupID -> IO ()
setOwnerAndGroup p u g = primPosixChown p (fromIntegral u) (fromIntegral g) True
setSymbolicLinkOwnerAndGroup p u g =
  primPosixChown p (fromIntegral u) (fromIntegral g) False

setFdOwnerAndGroup :: Fd -> UserID -> GroupID -> IO ()
setFdOwnerAndGroup (Fd n) u g =
  primPosixFchown (fromIntegral n) (fromIntegral u) (fromIntegral g)

setFileSize :: FilePath -> FileOffset -> IO ()
setFileSize p n = primPosixTruncate p (toInteger n)

setFdSize :: Fd -> FileOffset -> IO ()
setFdSize (Fd fd) n = primPosixFtruncate (fromIntegral fd) (toInteger n)

-- | The POSIX path variables (unix's others raise an error here).
data PathVar
  = FileSizeBits | LinkLimit | InputLineLimit | InputQueueLimit
  | FileNameLimit | PathNameLimit | PipeBufferLimit | SymbolicLinkLimit
  | SetOwnerAndGroupIsRestricted | FileNamesAreNotTruncated | VDisableChar
  | AsyncIOAvailable | PrioIOAvailable | SyncIOAvailable
  deriving (Eq, Show)

pathVarNumber :: PathVar -> Int
pathVarNumber v = case v of
  LinkLimit -> 0
  InputLineLimit -> 1
  InputQueueLimit -> 2
  FileNameLimit -> 3
  PathNameLimit -> 4
  PipeBufferLimit -> 5
  SetOwnerAndGroupIsRestricted -> 6
  FileNamesAreNotTruncated -> 7
  VDisableChar -> 8
  _ -> error ("getPathVar: " ++ show v ++ " is not supported")

getPathVar :: FilePath -> PathVar -> IO Limit
getPathVar p v = fmap fromInteger (primPosixPathconf p (pathVarNumber v))

getFdPathVar :: Fd -> PathVar -> IO Limit
getFdPathVar (Fd n) v =
  fmap fromInteger (primPosixFpathconf (fromIntegral n) (pathVarNumber v))

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
  setUserIDMode, setGroupIDMode, stdFileMode, accessModes :: FileMode
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
setUserIDMode = 2048
setGroupIDMode = 1024
stdFileMode = 438
accessModes = 511

unionFileModes, intersectFileModes :: FileMode -> FileMode -> FileMode
unionFileModes a b = a .|. b
intersectFileModes a b = a .&. b
