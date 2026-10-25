-- Control.Concurrent (base).  Yale Haskell's runtime has one thread:
-- forkIO runs the new thread's action to completion before it returns
-- (an exception in it is reported on stderr, as GHC does, and does not
-- reach the parent).  Programs whose threads only hand results back
-- through MVars or Chans (workers, then a collector) run as with GHC; a
-- thread that waits for another one fails with "blocked indefinitely".
module Control.Concurrent (
    ThreadId, myThreadId, forkIO, forkFinally, forkIOWithUnmask, forkOS,
    forkOSWithUnmask, forkOnWithUnmask,
    forkOn, killThread, throwTo, yield, threadDelay, getNumCapabilities,
    threadWaitRead, threadWaitWrite,
    setNumCapabilities, rtsSupportsBoundThreads, isCurrentThreadBound,
    threadCapability, mkWeakThreadId,
    module Control.Concurrent.MVar, module Control.Concurrent.Chan
  ) where

import Control.Concurrent.MVar
import Control.Concurrent.Chan
import Control.Exception (SomeException, try)
import Data.IORef
import System.IO (hPutStrLn, stderr)
import System.IO.Unsafe (unsafePerformIO)
import ParallelPrims (primNumCapabilities)
import System.Posix.Types (Fd(..))
import BasePrims (primWaitFd)

newtype ThreadId = ThreadId Int deriving (Eq, Ord)

instance Show ThreadId where
  show (ThreadId n) = "ThreadId " ++ show n

-- the last thread number given out
counter :: IORef Int
counter = unsafePerformIO (newIORef 1)

myThreadId :: IO ThreadId
myThreadId = return (ThreadId 1)

forkIO :: IO () -> IO ThreadId
forkIO act = do
  n <- atomicModifyIORef counter (\k -> (k + 1, k + 1))
  r <- try act
  case r of
    Left e -> hPutStrLn stderr ("<thread>: " ++ show (e :: SomeException))
    Right () -> return ()
  return (ThreadId n)

forkFinally :: IO a -> (Either SomeException a -> IO ()) -> IO ThreadId
forkFinally act fin = forkIO (try act >>= fin)

forkIOWithUnmask :: ((forall a . IO a -> IO a) -> IO ()) -> IO ThreadId
forkIOWithUnmask f = forkIO (f id)

forkOSWithUnmask :: ((forall a . IO a -> IO a) -> IO ()) -> IO ThreadId
forkOSWithUnmask f = forkIO (f id)

forkOnWithUnmask :: Int -> ((forall a . IO a -> IO a) -> IO ()) -> IO ThreadId
forkOnWithUnmask _ f = forkIO (f id)

forkOS :: IO () -> IO ThreadId
forkOS = forkIO

forkOn :: Int -> IO () -> IO ThreadId
forkOn _ = forkIO

killThread :: ThreadId -> IO ()
killThread _ = return ()

throwTo :: ThreadId -> e -> IO ()
throwTo _ _ = return ()

yield :: IO ()
yield = return ()

-- The thread would sleep; with one thread there is nothing to wait for.
threadDelay :: Int -> IO ()
threadDelay _ = return ()

-- +RTS -N's (Control.Parallel's sparks use them; threads still run one
-- at a time)
getNumCapabilities :: IO Int
getNumCapabilities = primNumCapabilities

setNumCapabilities :: Int -> IO ()
setNumCapabilities _ = return ()

rtsSupportsBoundThreads :: Bool
rtsSupportsBoundThreads = False

isCurrentThreadBound :: IO Bool
isCurrentThreadBound = return False

threadCapability :: ThreadId -> IO (Int, Bool)
threadCapability _ = return (0, False)

mkWeakThreadId :: ThreadId -> IO ThreadId
mkWeakThreadId = return

-- | Block until the descriptor can be read, or written: there is one
-- Haskell thread (network's non-blocking sockets wait here).
threadWaitRead, threadWaitWrite :: Fd -> IO ()
threadWaitRead (Fd n) = primWaitFd (fromIntegral n) True
threadWaitWrite (Fd n) = primWaitFd (fromIntegral n) False

