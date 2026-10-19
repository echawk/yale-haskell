-- Ported from the time package, version 1.15 (BSD; Ashley Yakeley),
-- for Yale Haskell: no TH.Lift instances, no Safe Haskell.
{-# LANGUAGE LambdaCase, PatternSynonyms, ViewPatterns, DeriveDataTypeable, DeriveGeneric #-}

module Data.Time.Clock.Internal.UTCDiff where

import Data.Time.Clock.Internal.NominalDiffTime
import Data.Time.Clock.Internal.UTCTime
import Data.Time.Clock.POSIX

-- | addUTCTime a b = a + b
addUTCTime :: NominalDiffTime -> UTCTime -> UTCTime
addUTCTime x t = posixSecondsToUTCTime (x + (utcTimeToPOSIXSeconds t))

-- | diffUTCTime a b = a - b
diffUTCTime :: UTCTime -> UTCTime -> NominalDiffTime
diffUTCTime a b = (utcTimeToPOSIXSeconds a) - (utcTimeToPOSIXSeconds b)
