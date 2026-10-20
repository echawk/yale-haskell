-- GHC.Clock (base): a monotonic clock, from the Lisp's internal real
-- time (src/runtime/system-prims.mumble's prim.monotonic-nsec).
module GHC.Clock (getMonotonicTime, getMonotonicTimeNSec) where

import Data.Word (Word64)
import TimePrims (primMonotonicNSec)

-- | Seconds since some fixed, arbitrary point.
getMonotonicTime :: IO Double
getMonotonicTime = fmap (\n -> fromInteger n / 1.0e9) primMonotonicNSec

-- | Nanoseconds since some fixed, arbitrary point.
getMonotonicTimeNSec :: IO Word64
getMonotonicTimeNSec = fmap fromInteger primMonotonicNSec
