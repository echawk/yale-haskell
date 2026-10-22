-- Control.Concurrent.STM.TBQueue (stm): Control.Concurrent.STM's TBQueue.
module Control.Concurrent.STM.TBQueue (
    TBQueue, newTBQueue, newTBQueueIO, writeTBQueue, readTBQueue, tryReadTBQueue, flushTBQueue, lengthTBQueue, isEmptyTBQueue, isFullTBQueue
  ) where

import Control.Concurrent.STM
