-- Time.hs -- the Haskell 98 Time library
--
-- Interface as in the Haskell 98 Library Report, chapter 16.
-- formatCalendarTime and the show2/show3 helpers are the Report's code,
-- adapted; the Report carries this notice:
--
--   The authors intend this Report to belong to the entire Haskell
--   community, and so we grant permission to copy and distribute it for
--   any purpose, provided that it is reproduced in its entirety,
--   including this Notice.  Modified versions of this Report may also
--   be copied and distributed for any purpose, provided that the
--   modified version is clearly presented as such, and that it does not
--   claim to be a definition of the language Haskell 98.
--
-- The rest is written for Yale Haskell.  A ClockTime is seconds and
-- picoseconds since 1970-01-01 00:00 UTC.  The calendar arithmetic is
-- done here in Haskell (proleptic Gregorian calendar); only the clock
-- and the local time zone come from Lisp (TimePrims.hi).
-- addToClockTime and diffClockTimes follow GHC's old-time library:
-- diffClockTimes gives only seconds and picoseconds, and
-- addToClockTime adds months and years to the calendar date (in UTC).
--
-- Stopgaps until the compiler has records and the Prelude is H98:
--   * CalendarTime and TimeDiff are positional constructors with
--     hand-written field selectors; record syntax is not available.

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

import Locale
import TimePrims

data ClockTime = TOD Integer Integer       -- seconds, picoseconds
                 deriving (Eq, Ord)

data Month =  January   | February | March    | April
           |  May       | June     | July     | August
           |  September | October  | November | December
           deriving (Eq, Ord, Enum, Ix, Show, Read)

data Day   =  Sunday | Monday  | Tuesday  | Wednesday | Thursday
           |  Friday | Saturday
           deriving (Eq, Ord, Enum, Ix, Show, Read)

-- CalendarTime year month day hour min sec picosec wday yday tzname tz isdst
data CalendarTime = CalendarTime
        Int Month Int Int Int Int Integer Day Int String Int Bool
        deriving (Eq, Ord, Show, Read)

ctYear, ctDay, ctHour, ctMin, ctSec, ctYDay, ctTZ :: CalendarTime -> Int
ctYear    (CalendarTime x _ _ _ _ _ _ _ _ _ _ _) = x
ctDay     (CalendarTime _ _ x _ _ _ _ _ _ _ _ _) = x
ctHour    (CalendarTime _ _ _ x _ _ _ _ _ _ _ _) = x
ctMin     (CalendarTime _ _ _ _ x _ _ _ _ _ _ _) = x
ctSec     (CalendarTime _ _ _ _ _ x _ _ _ _ _ _) = x
ctYDay    (CalendarTime _ _ _ _ _ _ _ _ x _ _ _) = x
ctTZ      (CalendarTime _ _ _ _ _ _ _ _ _ _ x _) = x

ctMonth   :: CalendarTime -> Month
ctMonth   (CalendarTime _ x _ _ _ _ _ _ _ _ _ _) = x

ctPicosec :: CalendarTime -> Integer
ctPicosec (CalendarTime _ _ _ _ _ _ x _ _ _ _ _) = x

ctWDay    :: CalendarTime -> Day
ctWDay    (CalendarTime _ _ _ _ _ _ _ x _ _ _ _) = x

ctTZName  :: CalendarTime -> String
ctTZName  (CalendarTime _ _ _ _ _ _ _ _ _ x _ _) = x

ctIsDST   :: CalendarTime -> Bool
ctIsDST   (CalendarTime _ _ _ _ _ _ _ _ _ _ _ x) = x

-- TimeDiff year month day hour min sec picosec
data TimeDiff = TimeDiff Int Int Int Int Int Int Integer
                deriving (Eq, Ord, Show, Read)

tdYear, tdMonth, tdDay, tdHour, tdMin, tdSec :: TimeDiff -> Int
tdYear    (TimeDiff x _ _ _ _ _ _) = x
tdMonth   (TimeDiff _ x _ _ _ _ _) = x
tdDay     (TimeDiff _ _ x _ _ _ _) = x
tdHour    (TimeDiff _ _ _ x _ _ _) = x
tdMin     (TimeDiff _ _ _ _ x _ _) = x
tdSec     (TimeDiff _ _ _ _ _ x _) = x

tdPicosec :: TimeDiff -> Integer
tdPicosec (TimeDiff _ _ _ _ _ _ x) = x

-- Enumerations as numbers (H98 would use fromEnum/toEnum).

monthToInt :: Month -> Int
monthToInt m = length (takeWhile (/= m) [January ..])

intToMonth :: Int -> Month
intToMonth n = [January ..] !! n

dayToInt :: Day -> Int
dayToInt d = length (takeWhile (/= d) [Sunday ..])

intToDay :: Int -> Day
intToDay n = [Sunday ..] !! n

-- Clock

getClockTime            :: IO ClockTime
getClockTime            =  primGetClockTime `thenIO` \(s, ps) ->
                           returnIO (TOD s ps)

picosPerSec :: Integer
picosPerSec = 1000000000000

-- Normalise seconds and picoseconds so that 0 <= ps < picosPerSec.
mkTOD :: Integer -> Integer -> ClockTime
mkTOD s ps = TOD (s + q) r  where (q, r) = ps `divMod` picosPerSec

addToClockTime          :: TimeDiff     -> ClockTime -> ClockTime
addToClockTime (TimeDiff year mon day hour min sec psec) (TOD cs cps) =
    let secs  = toInteger sec + 60 * toInteger min + 3600 * toInteger hour
                + 86400 * toInteger day
        cal   = toUTCTime (mkTOD (cs + secs) (cps + psec))
        months = monthToInt (ctMonth cal) + mon + 12 * year
        (dy, m) = months `divMod` 12
        CalendarTime y _ d h mi s ps wd yd tzn tz dst = cal
    in  toClockTime (CalendarTime (y + dy) (intToMonth m) d h mi s ps
                                  wd yd tzn tz dst)

diffClockTimes          :: ClockTime    -> ClockTime -> TimeDiff
diffClockTimes (TOD sa pa) (TOD sb pb) =
    TimeDiff 0 0 0 0 0 (fromInteger (sa - sb)) (pa - pb)

-- Calendar.  Days since 1970-01-01 <-> (year, month 1-12, day 1-31),
-- after Howard Hinnant's days_from_civil / civil_from_days algorithms.

daysFromCivil :: Integer -> Integer -> Integer -> Integer
daysFromCivil y0 m d =
    let y   = if m <= 2 then y0 - 1 else y0
        era = y `div` 400
        yoe = y - era * 400
        mp  = (m + 9) `mod` 12
        doy = (153 * mp + 2) `div` 5 + d - 1
        doe = yoe * 365 + yoe `div` 4 - yoe `div` 100 + doy
    in  era * 146097 + doe - 719468

civilFromDays :: Integer -> (Integer, Integer, Integer)
civilFromDays z0 =
    let z   = z0 + 719468
        era = z `div` 146097
        doe = z - era * 146097
        yoe = (doe - doe `div` 1460 + doe `div` 36524 - doe `div` 146096)
              `div` 365
        doy = doe - (365 * yoe + yoe `div` 4 - yoe `div` 100)
        mp  = (5 * doy + 2) `div` 153
        d   = doy - (153 * mp + 2) `div` 5 + 1
        m   = if mp < 10 then mp + 3 else mp - 9
        y   = yoe + era * 400
    in  (if m <= 2 then y + 1 else y, m, d)

toUTCTime               :: ClockTime    -> CalendarTime
toUTCTime t             =  calendarAt t 0 "UTC" False

-- The calendar time of t in a zone offset seconds east of UTC.
calendarAt :: ClockTime -> Int -> String -> Bool -> CalendarTime
calendarAt (TOD s0 ps) offset name dst =
    let s          = s0 + toInteger offset
        (days, ds) = s `divMod` 86400
        (y, m, d)  = civilFromDays days
        yday       = days - daysFromCivil y 1 1
        wday       = (days + 4) `mod` 7          -- 1970-01-01 was a Thursday
    in  CalendarTime (fromInteger y) (intToMonth (fromInteger m - 1))
                     (fromInteger d) (fromInteger (ds `div` 3600))
                     (fromInteger (ds `mod` 3600 `div` 60))
                     (fromInteger (ds `mod` 60)) ps
                     (intToDay (fromInteger wday)) (fromInteger yday)
                     name offset dst

toCalendarTime          :: ClockTime    -> IO CalendarTime
toCalendarTime t@(TOD s _) =
    primTimeZoneOffset s `thenIO` \offset ->
    primIsDST s `thenIO` \dst ->
    primTimeZoneName s `thenIO` \name ->
    returnIO (calendarAt t offset name dst)

toClockTime             :: CalendarTime -> ClockTime
toClockTime (CalendarTime year mon day hour min sec psec _ _ _ tz _) =
    let days = daysFromCivil (toInteger year) (toInteger (monthToInt mon + 1))
                             (toInteger day)
        secs = days * 86400 + toInteger hour * 3600 + toInteger min * 60
               + toInteger sec - toInteger tz
    in  mkTOD secs psec

calendarTimeToString    :: CalendarTime -> String
calendarTimeToString    =  formatCalendarTime defaultTimeLocale "%c"

-- From the Report (fromEnum replaced by monthToInt/dayToInt, and %s
-- defined as seconds since the epoch).
formatCalendarTime :: TimeLocale -> String -> CalendarTime -> String
formatCalendarTime l fmt ct@(CalendarTime year mon day hour min sec sdec
                                           wday yday tzname _ _) =
        doFmt fmt
  where doFmt ('%':c:cs) = decode c ++ doFmt cs
        doFmt (c:cs) = c : doFmt cs
        doFmt "" = ""

        to12 :: Int -> Int
        to12 h = let h' = h `mod` 12 in if h' == 0 then 12 else h'

        decode 'A' = fst (wDays l  !! dayToInt wday)
        decode 'a' = snd (wDays l  !! dayToInt wday)
        decode 'B' = fst (months l !! monthToInt mon)
        decode 'b' = snd (months l !! monthToInt mon)
        decode 'h' = snd (months l !! monthToInt mon)
        decode 'C' = show2 (year `quot` 100)
        decode 'c' = doFmt (dateTimeFmt l)
        decode 'D' = doFmt "%m/%d/%y"
        decode 'd' = show2 day
        decode 'e' = show2' day
        decode 'H' = show2 hour
        decode 'I' = show2 (to12 hour)
        decode 'j' = show3 yday
        decode 'k' = show2' hour
        decode 'l' = show2' (to12 hour)
        decode 'M' = show2 min
        decode 'm' = show2 (monthToInt mon + 1)
        decode 'n' = "\n"
        decode 'p' = (if hour < 12 then fst else snd) (amPm l)
        decode 'R' = doFmt "%H:%M"
        decode 'r' = doFmt (time12Fmt l)
        decode 'T' = doFmt "%H:%M:%S"
        decode 't' = "\t"
        decode 'S' = show2 sec
        decode 's' = let TOD s _ = toClockTime ct in show s
        decode 'U' = show2 ((yday + 7 - dayToInt wday) `div` 7)
        decode 'u' = show (let n = dayToInt wday in
                           if n == 0 then 7 else n)
        decode 'V' =
            let (week, days) =
                   (yday + 7 - if dayToInt wday > 0 then
                               dayToInt wday - 1 else 6) `divMod` 7
            in  show2 (if days >= 4 then
                          week+1
                       else if week == 0 then 53 else week)

        decode 'W' =
            show2 ((yday + 7 - if dayToInt wday > 0 then
                               dayToInt wday - 1 else 6) `div` 7)
        decode 'w' = show (dayToInt wday)
        decode 'X' = doFmt (timeFmt l)
        decode 'x' = doFmt (dateFmt l)
        decode 'Y' = show year
        decode 'y' = show2 (year `rem` 100)
        decode 'Z' = tzname
        decode '%' = "%"
        decode c   = [c]

show2, show2', show3 :: Int -> String
show2 x = [intToDigit (x `quot` 10), intToDigit (x `rem` 10)]

show2' x = if x < 10 then [ ' ', intToDigit x] else show2 x

show3 x = intToDigit (x `quot` 100) : show2 (x `rem` 100)

intToDigit :: Int -> Char
intToDigit i = chr (ord '0' + i)
