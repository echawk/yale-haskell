{-# LANGUAGE MagicHash, PatternSynonyms, ViewPatterns #-}
-- GHC.Word (base): the fixed-size word types and their GHC
-- constructors (W8# ...), as conversions from the unboxed type
-- (Word8# etc. are Word, GHC.Exts).
module GHC.Word (
    Word, Word8(W8#), Word16(W16#), Word32(W32#), Word64(W64#)
  ) where

import Data.Word
import GHC.Exts (Word8#, Word16#, Word32#, Word64#)

pattern W8# :: Word8# -> Word8
pattern W8# x <- (fromIntegral -> x)
  where W8# x = fromIntegral x

pattern W16# :: Word16# -> Word16
pattern W16# x <- (fromIntegral -> x)
  where W16# x = fromIntegral x

pattern W32# :: Word32# -> Word32
pattern W32# x <- (fromIntegral -> x)
  where W32# x = fromIntegral x

pattern W64# :: Word64# -> Word64
pattern W64# x <- (fromIntegral -> x)
  where W64# x = fromIntegral x
