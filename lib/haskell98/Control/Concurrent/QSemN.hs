-- Control.Concurrent.QSemN (base): a semaphore of a general quantity.
-- The quantity and the waiters (each with the amount it wants), first
-- come first served, in an MVar.
module Control.Concurrent.QSemN (QSemN, newQSemN, waitQSemN, signalQSemN) where

import Control.Concurrent.MVar

newtype QSemN = QSemN (MVar (Int, [(Int, MVar ())]))

newQSemN :: Int -> IO QSemN
newQSemN n
  | n < 0 = ioError (userError "newQSemN: Initial quantity must be non-negative")
  | otherwise = fmap QSemN (newMVar (n, []))

waitQSemN :: QSemN -> Int -> IO ()
waitQSemN (QSemN m) k = do
  (avail, waiters) <- takeMVar m
  if avail >= k && null waiters
    then putMVar m (avail - k, waiters)
    else do
      b <- newEmptyMVar
      putMVar m (avail, waiters ++ [(k, b)])
      takeMVar b

signalQSemN :: QSemN -> Int -> IO ()
signalQSemN (QSemN m) k = do
  (avail, waiters) <- takeMVar m
  (avail', waiters') <- wake (avail + k) waiters
  putMVar m (avail', waiters')
  where
    wake n ((w, b) : rest) | w <= n = putMVar b () >> wake (n - w) rest
    wake n ws = return (n, ws)
