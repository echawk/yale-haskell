-- Control.Concurrent.STM.TQueue (stm): Control.Concurrent.STM's TQueue.
module Control.Concurrent.STM.TQueue (
    TQueue, newTQueue, newTQueueIO, writeTQueue, readTQueue, tryReadTQueue, isEmptyTQueue, flushTQueue
  ) where

import Control.Concurrent.STM
