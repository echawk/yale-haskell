import Control.Concurrent.STM
main = do
  v <- newTMVarIO (1 :: Int)
  old <- atomically (swapTMVar v 2)
  r <- atomically (tryReadTMVar v)
  atomically (writeTMVar v 9)
  n <- atomically (readTMVar v)
  print (old, r, n)
