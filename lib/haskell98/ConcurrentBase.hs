-- ConcurrentBase: Control.Concurrent's ThreadId and throwTo, which
-- Control.Exception exports too (as base's does; unliftio's E.throwTo),
-- in a module both import (Control.Concurrent imports Control.Exception).
module ConcurrentBase (ThreadId(..), throwTo) where

newtype ThreadId = ThreadId Int deriving (Eq, Ord)

instance Show ThreadId where
  show (ThreadId n) = "ThreadId " ++ show n

-- A forked thread has run to completion when forkIO returns (one Haskell
-- thread), so there is no thread to interrupt.
throwTo :: ThreadId -> e -> IO ()
throwTo _ _ = return ()
