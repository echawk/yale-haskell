-- Control.Concurrent (base).  A forked thread is a host thread
-- (bordeaux-threads: src/base/concurrent-runtime.lisp), and the main
-- thread's end ends the program, as with GHC's threaded runtime.  An
-- exception that escapes a thread is reported on stderr (ThreadKilled
-- silently).
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
import Control.Exception (SomeException, AsyncException(ThreadKilled), try,
                          throwTo, fromException, mask, mask_)
import System.IO (hPutStrLn, stderr)
import ParallelPrims (primNumCapabilities)
import ConcurrentPrims (primForkThread, primThreadDelay, primYield)
import System.Posix.Types (Fd(..))
import BasePrims (primWaitFd)
import ConcurrentBase (ThreadId(..), myThreadId, withMaskState)

forkIO :: IO () -> IO ThreadId
forkIO act = fmap ThreadId (primForkThread (try act >>= report))
  where
    report (Left e)
      | Just ThreadKilled <- fromException e = return ()
      | otherwise = hPutStrLn stderr ("<thread>: " ++ show (e :: SomeException))
    report (Right ()) = return ()

forkFinally :: IO a -> (Either SomeException a -> IO ()) -> IO ThreadId
forkFinally act fin = mask $ \restore -> forkIO (try (restore act) >>= fin)

-- (the new thread starts in its parent's masking state, here masked;
-- unmask unmasks, as base's unsafeUnmask)
forkIOWithUnmask :: ((forall a . IO a -> IO a) -> IO ()) -> IO ThreadId
forkIOWithUnmask f = mask_ (forkIO (f (withMaskState 0)))

forkOSWithUnmask :: ((forall a . IO a -> IO a) -> IO ()) -> IO ThreadId
forkOSWithUnmask = forkIOWithUnmask

forkOnWithUnmask :: Int -> ((forall a . IO a -> IO a) -> IO ()) -> IO ThreadId
forkOnWithUnmask _ = forkIOWithUnmask

forkOS :: IO () -> IO ThreadId
forkOS = forkIO

forkOn :: Int -> IO () -> IO ThreadId
forkOn _ = forkIO

killThread :: ThreadId -> IO ()
killThread t = throwTo t ThreadKilled

yield :: IO ()
yield = primYield

-- microseconds
threadDelay :: Int -> IO ()
threadDelay = primThreadDelay

-- +RTS -N's (Control.Parallel's sparks use them; threads still run one
-- at a time)
getNumCapabilities :: IO Int
getNumCapabilities = primNumCapabilities

setNumCapabilities :: Int -> IO ()
setNumCapabilities _ = return ()

rtsSupportsBoundThreads :: Bool
rtsSupportsBoundThreads = True

isCurrentThreadBound :: IO Bool
isCurrentThreadBound = return True

threadCapability :: ThreadId -> IO (Int, Bool)
threadCapability _ = return (0, False)

mkWeakThreadId :: ThreadId -> IO ThreadId
mkWeakThreadId = return

-- | Block until the descriptor can be read, or written (network's
-- non-blocking sockets wait here); other threads run meanwhile.
threadWaitRead, threadWaitWrite :: Fd -> IO ()
threadWaitRead (Fd n) = primWaitFd (fromIntegral n) True
threadWaitWrite (Fd n) = primWaitFd (fromIntegral n) False

