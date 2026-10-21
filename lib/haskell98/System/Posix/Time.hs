-- System.Posix.Time (unix): the time since the epoch.
module System.Posix.Time (epochTime) where

import PosixPrims (primPosixTime)
import System.Posix.Types (EpochTime)

epochTime :: IO EpochTime
epochTime = fmap fromInteger primPosixTime
