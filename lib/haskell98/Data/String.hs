-- Data.String (base).  OverloadedStrings makes a string literal
-- Data.String.fromString "..." (parser/exp-parser.mumble).
module Data.String (
    String, IsString(fromString), lines, words, unlines, unwords
  ) where

import Unsafe.Coerce (unsafeCoerce)

class IsString a where
  fromString :: String -> a

-- base: instance (a ~ Char) => IsString [a], so that "x" ++ s fixes
-- the element type later.  Without type equality constraints, this is
-- an instance for every [a]: a program GHC accepts uses it only at Char.
instance IsString [a] where
  fromString s = unsafeCoerce s
