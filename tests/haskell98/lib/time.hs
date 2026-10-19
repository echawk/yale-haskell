-- The time package (ported, lib/haskell98/Data/Time): calendars, formatting,
-- ISO 8601, parsing, local time.
import Data.Time
import Data.Time.Clock.POSIX
import Data.Time.Calendar.WeekDate
import Data.Time.Format.ISO8601

main :: IO ()
main = do
  let d = fromGregorian 2024 2 29
      t = UTCTime d (secondsToDiffTime 3723)
  print d
  print (toGregorian (addDays 1 d), toWeekDate d, isLeapYear 2024)
  print t
  putStrLn (formatTime defaultTimeLocale "%Y-%m-%d %H:%M:%S %a %b %j" t)
  print (iso8601Show t)
  print (parseTimeM True defaultTimeLocale "%Y-%m-%d" "2023-07-04" :: Maybe Day)
  print (diffUTCTime (addUTCTime 90 t) t, posixSecondsToUTCTime 0)
  now <- getCurrentTime
  tz <- getCurrentTimeZone
  print (now > t, length (timeZoneName tz) >= 0)
  print (utcToLocalTime utc t, diffDays (fromGregorian 2025 1 1) d)
