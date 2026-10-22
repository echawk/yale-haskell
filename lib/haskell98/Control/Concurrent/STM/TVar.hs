-- Control.Concurrent.STM.TVar (stm): Control.Concurrent.STM's TVar.
module Control.Concurrent.STM.TVar (
    TVar, newTVar, newTVarIO, readTVar, readTVarIO, writeTVar, modifyTVar, modifyTVar', stateTVar, swapTVar
  ) where

import Control.Concurrent.STM
