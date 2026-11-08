-- Control.Monad.ST (base): the strict state-thread monad (STBase), with
-- base's exports only: ioToST is GHC.IO's, unsafeIOToST and unsafeSTToIO
-- Control.Monad.ST.Unsafe's (random defines its own ioToST beside this).
module Control.Monad.ST (ST, runST, fixST, RealWorld, stToIO) where

import STBase (ST, runST, fixST, RealWorld, stToIO)
