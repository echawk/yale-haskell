-- GHC.Natural (base): Natural, as Numeric.Natural has it.
module GHC.Natural (
    Natural, naturalToInteger, naturalFromInteger, intToNatural,
    naturalToInt, wordToNatural, naturalToWord, minusNaturalMaybe
  ) where

import Numeric.Natural (Natural, minusNaturalMaybe)
import Data.Word (Word)

naturalToInteger :: Natural -> Integer
naturalToInteger = toInteger

naturalFromInteger :: Integer -> Natural
naturalFromInteger = fromInteger

intToNatural :: Int -> Natural
intToNatural = fromIntegral

naturalToInt :: Natural -> Int
naturalToInt = fromIntegral

wordToNatural :: Word -> Natural
wordToNatural = fromIntegral

naturalToWord :: Natural -> Word
naturalToWord = fromIntegral
