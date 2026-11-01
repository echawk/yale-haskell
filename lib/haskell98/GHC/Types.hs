{-# LANGUAGE MagicHash #-}
-- GHC.Types (ghc-prim): GHC.Exts here, and LinearTypes' Multiplicity
-- (multiplicities are not checked: a %m -> b is a -> b).
module GHC.Types (module GHC.Exts, Int, Double, Char, Bool(..),
                  Multiplicity(One, Many), IO(IO)) where

import GHC.IO (IO(IO))
import GHC.Exts hiding (IsList(..), Item, IsString(..))

data Multiplicity = One | Many
