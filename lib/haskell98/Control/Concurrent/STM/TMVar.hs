-- Control.Concurrent.STM.TMVar (stm): Control.Concurrent.STM's TMVar.
module Control.Concurrent.STM.TMVar (
    TMVar, newTMVar, newEmptyTMVar, newTMVarIO, newEmptyTMVarIO, takeTMVar, putTMVar, readTMVar, tryTakeTMVar, tryPutTMVar, isEmptyTMVar, swapTMVar, tryReadTMVar, writeTMVar
  ) where

import Control.Concurrent.STM
