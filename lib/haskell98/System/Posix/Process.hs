-- System.Posix.Process (unix), a subset: the process id.
module System.Posix.Process (getProcessID) where

import PosixPrims (primGetProcessID)
import System.Posix.Types (ProcessID)

getProcessID :: IO ProcessID
getProcessID = fmap fromIntegral primGetProcessID
