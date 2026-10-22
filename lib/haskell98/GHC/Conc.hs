-- GHC.Conc (base): the capabilities are +RTS -N's; par and pseq are
-- Control.Parallel's; STM and TVar are stm's (Control.Monad.STM,
-- Control.Concurrent.STM), as base defines them here.
module GHC.Conc (numCapabilities, getNumCapabilities, setNumCapabilities,
                 getNumProcessors, pseq, par, labelThread,
                 STM, atomically, retry, orElse, throwSTM, catchSTM,
                 unsafeIOToSTM, TVar, newTVar, newTVarIO, readTVar,
                 readTVarIO, writeTVar,
                 module Control.Concurrent) where

import Control.Concurrent
import Control.Monad.STM
import Control.Concurrent.STM (TVar, newTVar, newTVarIO, readTVar, readTVarIO, writeTVar)
import Control.Parallel (par, pseq)
import System.IO.Unsafe (unsafePerformIO)

numCapabilities :: Int
numCapabilities = unsafePerformIO getNumCapabilities

getNumProcessors :: IO Int
getNumProcessors = return 1


-- | A name for the thread in GHC's debugging output; none here.
labelThread :: ThreadId -> String -> IO ()
labelThread _ _ = return ()
