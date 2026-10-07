-- Haskell 98 has no C-T rule: this module defines neither the class
-- Describe nor the type Box, but may still declare the instance.
module Main where

import CtClass
import CtType

instance Describe Box where
  describe (Box n) = "box " ++ show n

instance Describe Bool where
  describe b = if b then "yes" else "no"

main = appendChan stdout (unlines [describe (Box 3), describe True]) abort done
