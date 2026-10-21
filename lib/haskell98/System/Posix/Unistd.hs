-- System.Posix.Unistd (unix), a subset: the system's identification
-- (from the Lisp's own) and sleeping.
module System.Posix.Unistd (
    SystemID(..), getSystemID, sleep, usleep, nanosleep
  ) where

import PosixPrims (primPosixUname, primPosixSleep)
import Control.Concurrent (threadDelay)

data SystemID = SystemID
  { systemName :: String, nodeName :: String, release :: String,
    version :: String, machine :: String }
  deriving (Eq, Read, Show)

getSystemID :: IO SystemID
getSystemID = return (SystemID (primPosixUname 0) (primPosixUname 1)
                        (primPosixUname 2) (primPosixUname 3) (primPosixUname 4))

-- | Sleeps for the seconds given, returning 0 (the seconds left).
sleep :: Int -> IO Int
sleep = primPosixSleep

usleep :: Int -> IO ()
usleep = threadDelay

nanosleep :: Integer -> IO ()
nanosleep ns = threadDelay (fromInteger (ns `div` 1000))
