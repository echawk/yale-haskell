-- Locale.hs -- the Haskell 98 Locale library
--
-- From the Haskell 98 Library Report, chapter 15 (the Report's code,
-- adapted):
--
--   The authors intend this Report to belong to the entire Haskell
--   community, and so we grant permission to copy and distribute it for
--   any purpose, provided that it is reproduced in its entirety,
--   including this Notice.  Modified versions of this Report may also
--   be copied and distributed for any purpose, provided that the
--   modified version is clearly presented as such, and that it does not
--   claim to be a definition of the language Haskell 98.
--
-- Changes for Yale Haskell (stopgaps until the compiler has records
-- and the Prelude has Show):
--   * TimeLocale is an ordinary positional constructor; the field
--     selectors are written out by hand.  Record construction and
--     update syntax is not available.

module Locale(TimeLocale(..), wDays, months, amPm, dateTimeFmt, dateFmt,
              timeFmt, time12Fmt, defaultTimeLocale) where

data TimeLocale = TimeLocale
        [(String, String)]      -- wDays: full and abbreviated week days
        [(String, String)]      -- months: full and abbreviated months
        (String, String)        -- amPm: AM/PM symbols
        String String           -- dateTimeFmt, dateFmt
        String String           -- timeFmt, time12Fmt
        deriving (Eq, Ord, Show, Read)

wDays, months         :: TimeLocale -> [(String, String)]
wDays  (TimeLocale x _ _ _ _ _ _) = x
months (TimeLocale _ x _ _ _ _ _) = x

amPm                  :: TimeLocale -> (String, String)
amPm   (TimeLocale _ _ x _ _ _ _) = x

dateTimeFmt, dateFmt, timeFmt, time12Fmt :: TimeLocale -> String
dateTimeFmt (TimeLocale _ _ _ x _ _ _) = x
dateFmt     (TimeLocale _ _ _ _ x _ _) = x
timeFmt     (TimeLocale _ _ _ _ _ x _) = x
time12Fmt   (TimeLocale _ _ _ _ _ _ x) = x

defaultTimeLocale :: TimeLocale
defaultTimeLocale =  TimeLocale
        [("Sunday",   "Sun"),  ("Monday",    "Mon"),
         ("Tuesday",  "Tue"),  ("Wednesday", "Wed"),
         ("Thursday", "Thu"),  ("Friday",    "Fri"),
         ("Saturday", "Sat")]

        [("January",   "Jan"), ("February",  "Feb"),
         ("March",     "Mar"), ("April",     "Apr"),
         ("May",       "May"), ("June",      "Jun"),
         ("July",      "Jul"), ("August",    "Aug"),
         ("September", "Sep"), ("October",   "Oct"),
         ("November",  "Nov"), ("December",  "Dec")]

        ("AM", "PM")
        "%a %b %e %H:%M:%S %Z %Y"
        "%m/%d/%y"
        "%H:%M:%S"
        "%I:%M:%S %p"
