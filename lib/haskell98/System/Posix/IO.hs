-- System.Posix.IO (unix), a subset: opening, closing and duplicating file
-- descriptors, their options, and the descriptor under a Handle.
module System.Posix.IO (
    stdInput, stdOutput, stdError,
    OpenMode(ReadOnly, WriteOnly, ReadWrite),
    OpenFileFlags(OpenFileFlags, append, exclusive, noctty, nonBlock, trunc),
    defaultFileFlags, openFd, createFile, closeFd, dup, dupTo,
    FdOption(AppendOnWrite, CloseOnExec, NonBlockingRead, SynchronousWrites),
    setFdOption, handleToFd, fdToHandle
  ) where

import PosixPrims
import IOBase (Handle(Handle))
import System.Posix.Types

stdInput, stdOutput, stdError :: Fd
stdInput = Fd 0
stdOutput = Fd 1
stdError = Fd 2

data OpenMode = ReadOnly | WriteOnly | ReadWrite deriving (Eq, Show)

data OpenFileFlags = OpenFileFlags
  { append :: Bool, exclusive :: Bool, noctty :: Bool,
    nonBlock :: Bool, trunc :: Bool }
  deriving (Eq, Show)

defaultFileFlags :: OpenFileFlags
defaultFileFlags = OpenFileFlags False False False False False

-- unix 2.7's openFd: the creation mode, if any, and the flags
openFd :: FilePath -> OpenMode -> Maybe FileMode -> OpenFileFlags -> IO Fd
openFd path mode creat flags =
  fmap fromIntegral
       (primPosixOpen path access (maybe (-1) fromIntegral creat)
                      (append flags) (exclusive flags) (noctty flags)
                      (nonBlock flags) (trunc flags))
  where access = case mode of { ReadOnly -> 0; WriteOnly -> 1; ReadWrite -> 2 }

createFile :: FilePath -> FileMode -> IO Fd
createFile path m = openFd path WriteOnly (Just m) defaultFileFlags { trunc = True }

closeFd :: Fd -> IO ()
closeFd (Fd n) = primPosixClose (fromIntegral n)

dup :: Fd -> IO Fd
dup (Fd n) = fmap fromIntegral (primPosixDup (fromIntegral n))

dupTo :: Fd -> Fd -> IO Fd
dupTo (Fd a) (Fd b) = fmap fromIntegral (primPosixDup2 (fromIntegral a) (fromIntegral b))

data FdOption = AppendOnWrite | CloseOnExec | NonBlockingRead | SynchronousWrites
  deriving (Eq, Show)

setFdOption :: Fd -> FdOption -> Bool -> IO ()
setFdOption (Fd n) opt on = primPosixSetFdOption (fromIntegral n) code on
  where code = case opt of
          AppendOnWrite -> 0
          CloseOnExec -> 1
          NonBlockingRead -> 2
          SynchronousWrites -> 3

handleToFd :: Handle -> IO Fd
handleToFd (Handle h) = fmap fromIntegral (primHandleToFd h)

-- A binary handle (one Char per byte) on the descriptor, for reading and
-- writing.
fdToHandle :: Fd -> IO Handle
fdToHandle (Fd n) = fmap Handle (primFdToHandle (fromIntegral n) 2 ("<fd " ++ show n ++ ">"))
