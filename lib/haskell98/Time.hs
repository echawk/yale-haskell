-- Time: the Haskell 98 library (Report 98, chapter 13), its ClockTime
-- abstract; TimeBase.hs defines it.
module Time (
        ClockTime,
        Month(January,February,March,April,May,June,
              July,August,September,October,November,December),
        Day(Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday),
        CalendarTime(CalendarTime), ctYear, ctMonth, ctDay, ctHour, ctMin,
              ctSec, ctPicosec, ctWDay, ctYDay, ctTZName, ctTZ, ctIsDST,
        TimeDiff(TimeDiff), tdYear, tdMonth, tdDay, tdHour, tdMin, tdSec,
              tdPicosec,
        getClockTime, addToClockTime, diffClockTimes,
        toCalendarTime, toUTCTime, toClockTime,
        calendarTimeToString, formatCalendarTime
        ) where

import TimeBase
