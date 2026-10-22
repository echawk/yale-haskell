-- Control.Monad.Identity (mtl): Identity and IdentityT (as mtl 2.3), with
-- Control.Monad and Control.Monad.Fix re-exported, as mtl before 2.3 does.
module Control.Monad.Identity (
    module Data.Functor.Identity, module Control.Monad, module Control.Monad.Fix,
    IdentityT(IdentityT, runIdentityT), mapIdentityT
  ) where

import Data.Functor.Identity
import Control.Monad
import Control.Monad.Fix
import Control.Monad.Trans.Identity (IdentityT(IdentityT, runIdentityT), mapIdentityT)
