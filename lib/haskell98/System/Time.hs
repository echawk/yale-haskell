-- System.Time (old-time): the Haskell 98 library Time under its
-- hierarchical name, with old-time's additions noTimeDiff and
-- normalizeTimeDiff.
module System.Time (module Time, noTimeDiff, normalizeTimeDiff) where

import Time

noTimeDiff :: TimeDiff
noTimeDiff = TimeDiff 0 0 0 0 0 0 0

-- As old-time: a month is 30 days and a year 365.
normalizeTimeDiff :: TimeDiff -> TimeDiff
normalizeTimeDiff td =
  let rest0 = toInteger (tdSec td)
               + 60 * (toInteger (tdMin td)
                    + 60 * (toInteger (tdHour td)
                         + 24 * (toInteger (tdDay td)
                              + 30 * toInteger (tdMonth td)
                              + 365 * toInteger (tdYear td))))
      (diffYears,  rest1)    = rest0 `quotRem` (365 * 24 * 3600)
      (diffMonths, rest2)    = rest1 `quotRem` (30 * 24 * 3600)
      (diffDays,   rest3)    = rest2 `quotRem` (24 * 3600)
      (diffHours,  rest4)    = rest3 `quotRem` 3600
      (diffMins,   diffSecs) = rest4 `quotRem` 60
  in td { tdYear = fromInteger diffYears, tdMonth = fromInteger diffMonths,
          tdDay = fromInteger diffDays, tdHour = fromInteger diffHours,
          tdMin = fromInteger diffMins, tdSec = fromInteger diffSecs }
