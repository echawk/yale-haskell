-- Control.Concurrent's threads are host threads (bordeaux-threads): MVars
-- and Chans that wait, killThread and throwTo, masking, STM's retry and
-- orElse, atomicModifyIORef, and deadlock detection.
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception
import Control.Monad
import Data.IORef

main :: IO ()
main = do
  -- a reply through an MVar, from a thread that sleeps first
  box <- newEmptyMVar
  _ <- forkIO (threadDelay 20000 >> putMVar box "late")
  takeMVar box >>= putStrLn
  -- a channel between two threads
  c <- newChan
  _ <- forkIO (mapM_ (writeChan c) [1 .. 100 :: Int])
  ys <- replicateM 100 (readChan c)
  print (sum ys)
  -- killThread interrupts a sleeping thread, whose finally runs
  done <- newEmptyMVar
  t <- forkIO (threadDelay 10000000 `finally` putMVar done "finalizer ran")
  threadDelay 1000
  killThread t
  takeMVar done >>= putStrLn
  -- and a thread waiting on an MVar
  done2 <- newEmptyMVar
  never <- newEmptyMVar :: IO (MVar ())
  t2 <- forkIO (takeMVar never `catch` \e -> putMVar done2 (show (e :: AsyncException)))
  threadDelay 1000
  throwTo t2 ThreadKilled
  takeMVar done2 >>= putStrLn
  -- a masked thread gets the exception when it unmasks (its work does not
  -- wait: a wait, threadDelay's too, is interruptible)
  ready <- newEmptyMVar
  go <- newEmptyMVar
  res <- newEmptyMVar
  t3 <- forkIO $ mask $ \restore -> do
    putMVar ready ()
    _ <- evaluate (sum [1 .. 3000000 :: Int])
    putMVar go "masked work done"
    restore (threadDelay 1000000) `catch` \e -> putMVar res (show (e :: AsyncException))
  takeMVar ready
  killThread t3
  takeMVar go >>= putStrLn
  takeMVar res >>= putStrLn
  -- many threads updating one MVar
  m <- newMVar (0 :: Int)
  ws <- forM [1 .. 8 :: Int] $ \_ -> do
    d <- newEmptyMVar
    _ <- forkIO (replicateM_ 200 (modifyMVar_ m (return . (+ 1))) >> putMVar d ())
    return d
  mapM_ takeMVar ws
  readMVar m >>= print
  -- atomicModifyIORef from many threads
  cnt <- newIORef (0 :: Int)
  ws2 <- forM [1 .. 8 :: Int] $ \_ -> do
    d <- newEmptyMVar
    _ <- forkIO (replicateM_ 500 (atomicModifyIORef' cnt (\x -> (x + 1, ()))) >> putMVar d ())
    return d
  mapM_ takeMVar ws2
  readIORef cnt >>= print
  -- STM: increments from many threads, and a transaction that retries
  -- until they are done
  tv <- newTVarIO (0 :: Int)
  forM_ [1 .. 10 :: Int] $ \_ -> forkIO (replicateM_ 100 (atomically (modifyTVar' tv (+ 1))))
  atomically (readTVar tv >>= \n -> check (n == 1000))
  readTVarIO tv >>= print
  q <- newTQueueIO
  _ <- forkIO (forM_ [1 .. 5 :: Int] (atomically . writeTQueue q))
  zs <- replicateM 5 (atomically (readTQueue q))
  print zs
  -- orElse: the first branch's retry undoes its writes
  a <- newTVarIO (0 :: Int)
  r <- atomically ((writeTVar a 5 >> retry) `orElse` (readTVar a))
  print r
  -- deadlocks
  r1 <- try (newEmptyMVar >>= takeMVar) :: IO (Either BlockedIndefinitelyOnMVar ())
  print r1
  r2 <- try (atomically retry) :: IO (Either BlockedIndefinitelyOnSTM ())
  print r2
  me <- myThreadId
  print me
