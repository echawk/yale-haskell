-- GHC.OverloadedLabels (base): the class only; the #label syntax is not
-- supported, but instances can be defined (and fromLabel used with a
-- type application).
module GHC.OverloadedLabels (IsLabel(fromLabel)) where

import GHC.TypeLits (Symbol)

class IsLabel x a where
  fromLabel :: a
