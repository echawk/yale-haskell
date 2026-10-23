-- Control.Concurrent.STM.TChan (stm): Control.Concurrent.STM's TChan.
module Control.Concurrent.STM.TChan (
    TChan, newTChan, newTChanIO, writeTChan, readTChan, tryReadTChan, isEmptyTChan,
    unGetTChan, peekTChan, tryPeekTChan
  ) where

import Control.Concurrent.STM
