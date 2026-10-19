-- Data.Time.Clock.Internal.SystemTime, from the time package (1.15),
-- for Yale Haskell: the system clock is TimePrims' primGetClockTime
-- (microseconds on SBCL), and there is no TAI clock.
{-# LANGUAGE DeriveDataTypeable, DeriveGeneric #-}
module Data.Time.Clock.Internal.SystemTime (
    SystemTime (..),
    getSystemTime,
    getTime_resolution,
    getTAISystemTime,
) where

import Control.DeepSeq
import Data.Data
import Data.Int (Int64)
import Data.Time.Clock.Internal.DiffTime
import Data.Word
import GHC.Generics
import TimePrims (primGetClockTime)

-- | 'SystemTime' is time returned by system clock functions.
-- Its semantics depends on the clock function, but the epoch is typically the beginning of 1970.
-- Note that 'systemNanoseconds' of 1E9 to 2E9-1 can be used to represent leap seconds.
data SystemTime = MkSystemTime
    { systemSeconds :: !Int64
    , systemNanoseconds :: !Word32
    }
    deriving (Eq, Ord, Show, Typeable, Data, Generic)

instance NFData SystemTime where
    rnf a = a `seq` ()

-- | Get the system time, epoch start of 1970 UTC, leap-seconds ignored.
getSystemTime :: IO SystemTime
getSystemTime = do
    (s, ps) <- primGetClockTime
    return (MkSystemTime (fromInteger s) (fromInteger (ps `div` 1000)))

-- | The resolution of 'getSystemTime', 'getCurrentTime', 'getPOSIXTime'.
getTime_resolution :: DiffTime
getTime_resolution = 1E-6

-- | No TAI clock.
getTAISystemTime :: Maybe (DiffTime, IO SystemTime)
getTAISystemTime = Nothing
