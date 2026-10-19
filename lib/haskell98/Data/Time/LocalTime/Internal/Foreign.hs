-- Data.Time.LocalTime.Internal.Foreign, from the time package (1.15),
-- for Yale Haskell: the local time zone from TimePrims (the C library's
-- localtime_r on SBCL), as time's HsTime.c gets it.
module Data.Time.LocalTime.Internal.Foreign (
    getTimeZone,
    getCurrentTimeZone,
) where

import Data.Time.Clock.Internal.UTCTime
import Data.Time.Clock.POSIX
import Data.Time.Clock.System
import Data.Time.LocalTime.Internal.TimeZone
import TimePrims (primTimeZoneOffset, primIsDST, primTimeZoneName)

getTimeZoneSeconds :: Integer -> IO TimeZone
getTimeZoneSeconds s = do
    off <- primTimeZoneOffset s
    dst <- primIsDST s
    name <- primTimeZoneName s
    return (TimeZone (off `div` 60) dst name)

-- | Get the configured time-zone for a given time (varying as per summertime adjustments).
getTimeZone :: UTCTime -> IO TimeZone
getTimeZone t = getTimeZoneSeconds (floor (utcTimeToPOSIXSeconds t))

-- | Get the configured time-zone for the current time.
getCurrentTimeZone :: IO TimeZone
getCurrentTimeZone = getSystemTime >>= \t -> getTimeZoneSeconds (toInteger (systemSeconds t))
