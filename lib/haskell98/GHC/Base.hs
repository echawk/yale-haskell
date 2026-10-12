{-# LANGUAGE MagicHash #-}
-- GHC.Base (base), for programs that import primops from it: GHC.Exts
-- and the Prelude's basic types and operations.
module GHC.Base (
    module GHC.Exts, Int, Double, Float, Char, Word, Bool(..), Ordering(..),
    quotInt, remInt, divInt, modInt, ord, unsafeChr, ($!), until, asTypeOf,
    otherwise, id, const, (.), flip, ($)
  ) where

import GHC.Exts
import Data.Word (Word)
import Data.Char (ord, chr)

quotInt, remInt, divInt, modInt :: Int -> Int -> Int
quotInt = quot
remInt = rem
divInt = div
modInt = mod

unsafeChr :: Int -> Char
unsafeChr = chr
