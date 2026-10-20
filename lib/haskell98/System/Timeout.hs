-- System.Timeout (base).  Yale Haskell has no asynchronous exceptions
-- (a forked thread runs to completion: Control.Concurrent), so a
-- timeout cannot interrupt its action: with a positive bound the action
-- runs to completion and its result is Just; a negative bound is no
-- bound, and a zero one answers Nothing without running the action, as
-- in base.
module System.Timeout (Timeout, timeout) where

import Control.Exception (Exception)

-- | The exception base's timeout throws to its action (never thrown here).
data Timeout = Timeout deriving Eq

instance Show Timeout where
  show _ = "<<timeout>>"

instance Exception Timeout

timeout :: Int -> IO a -> IO (Maybe a)
timeout n action
  | n == 0 = return Nothing
  | otherwise = fmap Just action
