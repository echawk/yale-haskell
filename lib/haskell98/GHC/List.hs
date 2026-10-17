-- GHC.List (base): the list functions, and List, the list type
-- constructor by name.
module GHC.List (
    List, build, augment, module Data.List
  ) where

import Data.List
import GHC.Exts (build, augment)

type List = []
