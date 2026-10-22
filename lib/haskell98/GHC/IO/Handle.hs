-- GHC.IO.Handle (base): System.IO's handle operations, and hDuplicate
-- and hDuplicateTo (src/runtime/handle-prims.mumble).
module GHC.IO.Handle (
    Handle, BufferMode(..), hClose, hFlush, hGetBuffering, hSetBuffering,
    hSetBinaryMode, hGetEcho, hSetEcho, hIsEOF, hDuplicate, hDuplicateTo
  ) where

import IOPrims
import IOBase
import System.IO

hDuplicate :: Handle -> IO Handle
hDuplicate (Handle h) = fmap Handle (primHDuplicate h)

hDuplicateTo :: Handle -> Handle -> IO ()
hDuplicateTo (Handle h1) (Handle h2) = primHDuplicateTo h1 h2
