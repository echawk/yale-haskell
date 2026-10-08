-- Time and Locale: calendar conversion, formatting, arithmetic, and
-- the clock (checked for consistency, not printed).
module Main where
import Dialogue (stdout, appendChan, done, abort, thenIO, thenIO_)

import Time
import Locale

put :: String -> IO ()
put s = appendChan stdout s abort done

utc :: Int -> Month -> Int -> Int -> Int -> Int -> CalendarTime
utc y mo d h mi s = CalendarTime y mo d h mi s 0 Sunday 0 "UTC" 0 False

epoch :: ClockTime
epoch = toClockTime (utc 1970 January 1 0 0 0)

seconds :: Int -> TimeDiff
seconds n = TimeDiff 0 0 0 0 0 n 0

fmt :: String -> ClockTime -> String
fmt f t = formatCalendarTime defaultTimeLocale f (toUTCTime t)

billion :: ClockTime
billion = addToClockTime (seconds 1000000000) epoch

codes :: String
codes = "AaBbhCdeHIjklMmpSUuVWwYyZ"

main :: IO ()
main =
  put (calendarTimeToString (toUTCTime epoch) ++ "\n") `thenIO_`
  put (calendarTimeToString (toUTCTime billion) ++ "\n") `thenIO_`
  put (fmt "%s" billion ++ "\n") `thenIO_`
  put (concat [ c : '=' : fmt ['%', c] billion ++ " " | c <- codes ] ++ "\n") `thenIO_`
  put (fmt "%D|%T|%R|%r|%x|%X|%%|%n|%t|" billion ++ "\n") `thenIO_`
  put (show (ctYDay (toUTCTime billion), ctWDay (toUTCTime billion)) ++ "\n") `thenIO_`
  put (fmt "%c" (addToClockTime (seconds (-1)) epoch) ++ "\n") `thenIO_`
  put (fmt "%c" (toClockTime (utc 2000 February 29 12 0 0)) ++ "\n") `thenIO_`
  put (fmt "%c" (toClockTime (utc 1900 March 1 0 0 0)) ++ "\n") `thenIO_`
  put (fmt "%c" (toClockTime (utc 2024 December 31 23 59 59)) ++ " day "
       ++ show (ctYDay (toUTCTime (toClockTime (utc 2024 December 31 0 0 0))))
       ++ "\n") `thenIO_`
  -- a zone east of UTC
  put (fmt "%c" (toClockTime (CalendarTime 2001 September 9 3 46 40 0 Sunday 0
                                            "CEST" 7200 True)) ++ "\n") `thenIO_`
  -- months and years go through the calendar; Jan 31 + 1 month = Mar 3
  put (fmt "%c" (addToClockTime (TimeDiff 0 1 0 0 0 0 0)
                                (toClockTime (utc 2001 January 31 10 0 0))) ++ "\n") `thenIO_`
  put (fmt "%c" (addToClockTime (TimeDiff 1 13 2 3 4 5 0) billion) ++ "\n") `thenIO_`
  put (show (tdSec (diffClockTimes billion epoch),
             tdPicosec (diffClockTimes billion epoch)) ++ "\n") `thenIO_`
  put (show (epoch < billion, billion == billion,
             addToClockTime (TimeDiff 0 0 0 0 0 0 1500000000000) epoch
               == addToClockTime (seconds 1) (addToClockTime (TimeDiff 0 0 0 0 0 0 500000000000) epoch))
       ++ "\n") `thenIO_`
  getClockTime `thenIO` \t1 ->
  getClockTime `thenIO` \t2 ->
  put ("clock non-decreasing: " ++ show (t1 <= t2) ++ "\n") `thenIO_`
  put ("clock after 2024: " ++ show (ctYear (toUTCTime t1) >= 2024) ++ "\n") `thenIO_`
  toCalendarTime t1 `thenIO` \local ->
  put ("local round trip: " ++ show (toClockTime local == t1) ++ "\n") `thenIO_`
  toCalendarTime billion `thenIO` \lb ->
  put ("local offset sane: " ++ show (abs (ctTZ lb) <= 14 * 3600) ++ "\n") `thenIO_`
  put ("local round trip 2: " ++ show (toClockTime lb == billion) ++ "\n") `thenIO_`
  put (show (amPm defaultTimeLocale, dateFmt defaultTimeLocale) ++ "\n")
