-- System.Posix.Internals (base), the terminal functions darcs and its
-- like use: echo and canonical mode, on the controlling terminal.
module System.Posix.Internals (getEcho, setEcho, setCooked) where

import BasePrims (primGetEcho, primSetEcho)
import PosixPrims (primSetCooked)
import Foreign.C.Types (CInt)

getEcho :: CInt -> IO Bool
getEcho _ = primGetEcho

setEcho :: CInt -> Bool -> IO ()
setEcho _ on = primSetEcho on

setCooked :: CInt -> Bool -> IO ()
setCooked _ on = primSetCooked on
