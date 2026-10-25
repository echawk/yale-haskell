-- GHC.IO.Handle.FD (base): handles on file descriptors.  A handle on a
-- descriptor is binary (one Char per byte) and reads and writes, whatever
-- the mode (System.Posix.IO's fdToHandle).
module GHC.IO.Handle.FD (
    stdin, stdout, stderr, openFile, openBinaryFile, fdToHandle, fdToHandle'
  ) where

import System.IO (stdin, stdout, stderr, openFile, openBinaryFile, Handle, IOMode)
import qualified System.Posix.IO as P
import System.Posix.Types (Fd(..))
import Foreign.C.Types (CInt)
import GHC.IO.Device (IODeviceType)

fdToHandle :: CInt -> IO Handle
fdToHandle fd = P.fdToHandle (Fd fd)

-- the descriptor, its device type, whether it is a socket, a name for
-- messages, the mode and whether binary: a handle on the descriptor
fdToHandle' :: CInt -> Maybe IODeviceType -> Bool -> FilePath -> IOMode -> Bool -> IO Handle
fdToHandle' fd _ _ _ _ _ = P.fdToHandle (Fd fd)
