-- GHC.Event (base), its timer manager: a timeout is a thread that sleeps
-- until its deadline, which updateTimeout moves, then runs the action
-- (Control.Concurrent's threads are host threads).  There is no I/O
-- event manager: getSystemEventManager is Nothing, which programs take
-- as the non-threaded runtime's (network then waits with timeouts).
module GHC.Event (
    TimerManager, TimeoutKey, TimeoutCallback, getSystemTimerManager,
    registerTimeout, updateTimeout, unregisterTimeout,
    EventManager, getSystemEventManager,
    Event, evtRead, evtWrite
  ) where

import Control.Concurrent (ThreadId, forkIO, killThread, threadDelay)
import Data.Bits ((.|.), (.&.))
import Data.List (intercalate)
import PreludeModern (Semigroup((<>)), Monoid(mempty))
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

data EventManager = EventManager

getSystemEventManager :: IO (Maybe EventManager)
getSystemEventManager = return Nothing

-- The I/O events a registration waits for, as GHC's: a set (its Monoid),
-- shown as [evtRead,evtWrite] (lens' AsEmpty Event)
newtype Event = Event Int deriving Eq

evtRead, evtWrite :: Event
evtRead = Event 1
evtWrite = Event 2

instance Semigroup Event where
  Event a <> Event b = Event (a .|. b)

instance Monoid Event where
  mempty = Event 0

instance Show Event where
  show (Event e) = "[" ++ intercalate "," [n | (b, n) <- [(1, "evtRead"), (2, "evtWrite")], e .&. b /= 0] ++ "]"
