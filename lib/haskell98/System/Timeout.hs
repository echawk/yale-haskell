-- System.Timeout (base): as base's, a thread that sleeps for the bound
-- and then throws Timeout to the action's thread (Control.Concurrent's
-- threads are host threads).  A negative bound is no bound; a zero one
-- answers Nothing without running the action.
module System.Timeout (Timeout, timeout) where

import Control.Concurrent (myThreadId, forkIOWithUnmask, threadDelay, killThread)
import Control.Exception (Exception(..), handleJust, bracket, throwTo,
                          uninterruptibleMask_)
import Data.Unique (Unique, newUnique)

-- | The exception timeout throws to its action: each call's own.
newtype Timeout = Timeout Unique deriving Eq

instance Show Timeout where
  show _ = "<<timeout>>"

instance Exception Timeout

timeout :: Int -> IO a -> IO (Maybe a)
timeout n f
  | n < 0 = fmap Just f
  | n == 0 = return Nothing
  | otherwise = do
      pid <- myThreadId
      ex <- fmap Timeout newUnique
      handleJust (\e -> if e == ex then Just () else Nothing)
                 (\_ -> return Nothing)
                 (bracket (forkIOWithUnmask (\unmask ->
                             unmask (threadDelay n >> throwTo pid ex)))
                          (uninterruptibleMask_ . killThread)
                          (\_ -> fmap Just f))
