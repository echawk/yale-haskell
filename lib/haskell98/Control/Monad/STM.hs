-- Control.Monad.STM (stm): transactions (STMBase), which threads run one
-- at a time.
module Control.Monad.STM (
    STM, atomically, retry, orElse, check, throwSTM, catchSTM,
    unsafeIOToSTM
  ) where

import STMBase
