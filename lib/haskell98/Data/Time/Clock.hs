-- Data.Time.Clock (time): UTCTime from the system clock (Haskell 98's
-- Time) and NominalDiffTime, picosecond-exact, shown as time shows it
-- ("1.5s", "0.001234s").
module Data.Time.Clock (
    UTCTime, NominalDiffTime, DiffTime, getCurrentTime, diffUTCTime,
    addUTCTime, nominalDiffTimeToSeconds, secondsToNominalDiffTime,
    nominalDay, picosecondsToDiffTime, secondsToDiffTime
  ) where

import Time (toUTCTime, toClockTime, CalendarTime(..), ctYear, ctMonth,
             ctDay, ctHour, ctMin, ctSec, Month(January), Day(Thursday))
import TimePrims (primGetClockTime)
import Time (ClockTime, addToClockTime, TimeDiff(TimeDiff))
import Data.Ratio ((%), numerator, denominator)

-- picoseconds
newtype NominalDiffTime = NominalDiffTime Integer deriving (Eq, Ord)
type DiffTime = NominalDiffTime

newtype UTCTime = UTCTime Integer deriving (Eq, Ord)   -- picoseconds since 1970

picos :: Integer
picos = 1000000000000

instance Show NominalDiffTime where
  showsPrec p (NominalDiffTime n)
    | n < 0 = showParen (p > 6) (showChar '-' . showsPrec 7 (NominalDiffTime (negate n)))
    | otherwise =
        let (s, f) = n `quotRem` picos
            digits = reverse (dropWhile (== '0') (reverse (pad (show f))))
            pad d = replicate (12 - length d) '0' ++ d
        in showString (show s ++ (if null digits then "" else '.' : digits) ++ "s")

instance Num NominalDiffTime where
  NominalDiffTime a + NominalDiffTime b = NominalDiffTime (a + b)
  NominalDiffTime a - NominalDiffTime b = NominalDiffTime (a - b)
  NominalDiffTime a * NominalDiffTime b = NominalDiffTime ((a * b) `quot` picos)
  negate (NominalDiffTime a) = NominalDiffTime (negate a)
  abs (NominalDiffTime a) = NominalDiffTime (abs a)
  signum (NominalDiffTime a) = NominalDiffTime (signum a * picos)
  fromInteger n = NominalDiffTime (n * picos)

instance Real NominalDiffTime where
  toRational (NominalDiffTime a) = a % picos

instance Fractional NominalDiffTime where
  NominalDiffTime a / NominalDiffTime b = NominalDiffTime ((a * picos) `quot` b)
  fromRational r = NominalDiffTime ((numerator r * picos) `quot` denominator r)

instance RealFrac NominalDiffTime where
  properFraction (NominalDiffTime a) =
    let (q, r) = a `quotRem` picos in (fromInteger q, NominalDiffTime r)

instance Enum NominalDiffTime where
  toEnum n = NominalDiffTime (toInteger n)
  fromEnum (NominalDiffTime a) = fromInteger a

getCurrentTime :: IO UTCTime
getCurrentTime = do
  (s, ps) <- primGetClockTime
  return (UTCTime (s * picos + ps))

diffUTCTime :: UTCTime -> UTCTime -> NominalDiffTime
diffUTCTime (UTCTime a) (UTCTime b) = NominalDiffTime (a - b)

addUTCTime :: NominalDiffTime -> UTCTime -> UTCTime
addUTCTime (NominalDiffTime d) (UTCTime t) = UTCTime (t + d)

nominalDiffTimeToSeconds :: NominalDiffTime -> Rational
nominalDiffTimeToSeconds = toRational

secondsToNominalDiffTime :: Rational -> NominalDiffTime
secondsToNominalDiffTime = fromRational

secondsToDiffTime :: Integer -> DiffTime
secondsToDiffTime = fromInteger

picosecondsToDiffTime :: Integer -> DiffTime
picosecondsToDiffTime = NominalDiffTime

nominalDay :: NominalDiffTime
nominalDay = 86400

-- 2026-10-12 08:15:03.123456 UTC
instance Show UTCTime where
  show (UTCTime t) =
    let (s, ps) = t `divMod` picos
        -- the calendar time s seconds after the epoch
        epoch = toClockTime (CalendarTime 1970 January 1 0 0 0 0 Thursday 0 "UTC" 0 False)
        c = toUTCTime (addSeconds s epoch)
        two n = (if n < 10 then "0" else "") ++ show n
        frac = reverse (dropWhile (== '0') (reverse (let d = show ps in replicate (12 - length d) '0' ++ d)))
    in show (ctYear c) ++ "-" ++ two (fromEnum (ctMonth c) + 1) ++ "-" ++ two (ctDay c)
       ++ " " ++ two (ctHour c) ++ ":" ++ two (ctMin c) ++ ":" ++ two (ctSec c)
       ++ (if null frac then "" else '.' : frac) ++ " UTC"

addSeconds :: Integer -> ClockTime -> ClockTime
addSeconds n t = addToClockTime (TimeDiff 0 0 0 0 0 (fromInteger n) 0) t
