-- Control.Monad.ST.Lazy (base): Control.Monad.ST (here both are the strict
-- monad).
module Control.Monad.ST.Lazy (
    ST, runST, fixST, RealWorld, stToIO
  ) where

import Control.Monad.ST
