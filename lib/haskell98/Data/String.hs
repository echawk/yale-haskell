{-# LANGUAGE TypeFamilies #-}
-- Data.String (base).  OverloadedStrings makes a string literal
-- Data.String.fromString "..." (parser/exp-parser.mumble).
module Data.String (
    String, IsString(fromString), lines, words, unlines, unwords
  ) where

import Unsafe.Coerce (unsafeCoerce)

class IsString a where
  fromString :: String -> a

-- base's: (a ~ Char) => IsString [a], so that "x" ++ s fixes the
-- element type, and a literal at an undecided list type is a String.
instance (a ~ Char) => IsString [a] where
  fromString s = unsafeCoerce s
