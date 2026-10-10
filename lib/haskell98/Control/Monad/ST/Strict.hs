-- Control.Monad.ST.Strict (base): Control.Monad.ST (here both are the strict
-- monad).
module Control.Monad.ST.Strict (
    ST, runST, fixST, RealWorld, stToIO
  ) where

import Control.Monad.ST
