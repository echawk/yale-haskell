-- System.Posix (unix): the subset of System.Posix.Types, Files, IO and
-- Signals here, and sleep and the process id.
module System.Posix (
    module System.Posix.Types, module System.Posix.Files,
    module System.Posix.IO, module System.Posix.Signals,
    sleep, getProcessID
  ) where

import PosixPrims (primPosixSleep, primGetProcessID)
import System.Posix.Types
import System.Posix.Files
import System.Posix.IO
import System.Posix.Signals

sleep :: Int -> IO Int
sleep = primPosixSleep

getProcessID :: IO ProcessID
getProcessID = fmap fromIntegral primGetProcessID
