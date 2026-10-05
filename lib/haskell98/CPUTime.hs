-- CPUTime.hs -- the Haskell 98 CPUTime library
--
-- Interface as in the Haskell 98 Library Report, chapter 14.  CPU time
-- is Lisp's internal run time, in picoseconds; cpuTimePrecision is the
-- length of one internal time unit.

module CPUTime ( getCPUTime, cpuTimePrecision ) where

import CPUTimePrims

getCPUTime        :: IO Integer
getCPUTime        =  primGetCPUTime

cpuTimePrecision  :: Integer
cpuTimePrecision  =  primCPUTimePrecision
