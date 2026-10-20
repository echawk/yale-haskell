-- Data.Text.Lazy.Builder.Int (text): integers as builders.
module Data.Text.Lazy.Builder.Int (decimal, hexadecimal) where

import Data.Text.Lazy.Builder (Builder, fromString)
import Numeric (showHex)

decimal :: (Integral a, Show a) => a -> Builder
decimal = fromString . show . toInteger

-- | Of a non-negative number (as text's, an error for a negative one).
hexadecimal :: (Integral a, Show a) => a -> Builder
hexadecimal n
  | i < 0 = error "Data.Text.Lazy.Builder.Int.hexadecimal: applied to negative number"
  | otherwise = fromString (showHex i "")
  where i = toInteger n
