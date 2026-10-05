-- Driver for the Calendar demo (examples/demo/Calendar.hs): print the
-- Unix-style calendar for 1994 and the Bird & Wadler one for 1992.

module Main where

import Calendar

main = appendChan stdout (cal 1994 ++ calendar 1992) abort done
