-- ConcurrentBase: Control.Concurrent's ThreadId, in a module that
-- Control.Exception (throwTo) and Control.Concurrent both import.  A
-- thread is a host thread (src/base/concurrent-runtime.lisp); the main
-- thread is number 1.
module ConcurrentBase (ThreadId(..), myThreadId, withMaskState) where

import ConcurrentPrims (primMyThreadId, primGetMask, primSetMask)
import BasePrims (primCatchAny, primThrowExc)

newtype ThreadId = ThreadId Int deriving (Eq, Ord)

instance Show ThreadId where
  show (ThreadId n) = "ThreadId " ++ show n

myThreadId :: IO ThreadId
myThreadId = fmap ThreadId primMyThreadId

-- the action in masking state M (0 unmasked, 1 masked, 2 uninterruptibly),
-- then the state before (Control.Exception's mask, and base's
-- unsafeUnmask: withMaskState 0)
withMaskState :: Int -> IO a -> IO a
withMaskState m act = do
  old <- primGetMask
  if old == m
    then act
    else do
      primSetMask m
      r <- primCatchAny act (\e -> primSetMask old >> primThrowExc e)
      primSetMask old
      return r
