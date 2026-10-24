-- GHC.OverloadedLabels (base): the class.  With OverloadedLabels, #x is
-- fromLabel @"x" (parser/lexer.mumble).
module GHC.OverloadedLabels (IsLabel(fromLabel)) where

import GHC.TypeLits (Symbol)

class IsLabel x a where
  fromLabel :: a
