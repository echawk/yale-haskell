{-# LANGUAGE MagicHash, PatternSynonyms, ViewPatterns #-}
-- GHC.Int (base): the fixed-size int types and their GHC
-- constructors (I8# ...), as conversions from the unboxed type
-- (Int8# etc. are Int, GHC.Exts).
module GHC.Int (
    Int, Int8(I8#), Int16(I16#), Int32(I32#), Int64(I64#)
  ) where

import Data.Int
import GHC.Exts (Int8#, Int16#, Int32#, Int64#)

pattern I8# :: Int8# -> Int8
pattern I8# x <- (fromIntegral -> x)
  where I8# x = fromIntegral x

pattern I16# :: Int16# -> Int16
pattern I16# x <- (fromIntegral -> x)
  where I16# x = fromIntegral x

pattern I32# :: Int32# -> Int32
pattern I32# x <- (fromIntegral -> x)
  where I32# x = fromIntegral x

pattern I64# :: Int64# -> Int64
pattern I64# x <- (fromIntegral -> x)
  where I64# x = fromIntegral x
