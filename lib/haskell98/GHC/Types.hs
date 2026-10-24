{-# LANGUAGE MagicHash #-}
-- GHC.Types (ghc-prim): GHC.Exts here, and LinearTypes' Multiplicity
-- (multiplicities are not checked: a %m -> b is a -> b).
module GHC.Types (module GHC.Exts, Int, Double, Char, Bool(..),
                  Multiplicity(One, Many)) where

import GHC.Exts

data Multiplicity = One | Many
