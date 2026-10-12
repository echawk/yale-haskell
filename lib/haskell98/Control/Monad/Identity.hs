-- Control.Monad.Identity (mtl): Identity, with Control.Monad and
-- Control.Monad.Fix re-exported, as mtl before 2.3 does.
module Control.Monad.Identity (
    module Data.Functor.Identity, module Control.Monad, module Control.Monad.Fix
  ) where

import Data.Functor.Identity
import Control.Monad
import Control.Monad.Fix
