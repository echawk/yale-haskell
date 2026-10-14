-- Data.Time.Clock.POSIX (time): POSIX time, seconds since 1970-01-01 UTC.
module Data.Time.Clock.POSIX (
    POSIXTime, getPOSIXTime, utcTimeToPOSIXSeconds, posixSecondsToUTCTime,
    posixDayLength
  ) where

import Data.Time.Clock

posixDayLength :: NominalDiffTime
posixDayLength = nominalDay
