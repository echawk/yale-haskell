-- GHC.Event (base), its timer manager: a timeout is a thread that sleeps
-- until its deadline, which updateTimeout moves, then runs the action
-- (Control.Concurrent's threads are host threads).
module GHC.Event (
    TimerManager, TimeoutKey, TimeoutCallback, getSystemTimerManager,
    registerTimeout, updateTimeout, unregisterTimeout
  ) where

import Control.Concurrent (ThreadId, forkIO, killThread, threadDelay)
import Data.IORef
import Data.Time.Clock.POSIX (getPOSIXTime)

data TimerManager = TimerManager

-- the thread, and its deadline in microseconds since the epoch
data TimeoutKey = TimeoutKey ThreadId (IORef Integer)

instance Eq TimeoutKey where
  TimeoutKey a _ == TimeoutKey b _ = a == b

type TimeoutCallback = IO ()

getSystemTimerManager :: IO TimerManager
getSystemTimerManager = return TimerManager

nowMicros :: IO Integer
nowMicros = fmap (\t -> floor (t * 1000000)) getPOSIXTime

-- | The callback, after US microseconds.
registerTimeout :: TimerManager -> Int -> TimeoutCallback -> IO TimeoutKey
registerTimeout _ us cb = do
  now <- nowMicros
  deadline <- newIORef (now + toInteger us)
  t <- forkIO (wait deadline)
  return (TimeoutKey t deadline)
  where
    wait deadline = do
      d <- readIORef deadline
      now <- nowMicros
      if now >= d
        then cb
        else threadDelay (fromInteger (min (d - now) 1000000)) >> wait deadline

-- | The callback US microseconds from now instead.
updateTimeout :: TimerManager -> TimeoutKey -> Int -> IO ()
updateTimeout _ (TimeoutKey _ deadline) us = do
  now <- nowMicros
  writeIORef deadline (now + toInteger us)

unregisterTimeout :: TimerManager -> TimeoutKey -> IO ()
unregisterTimeout _ (TimeoutKey t _) = killThread t
