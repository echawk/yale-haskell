-- Control.Concurrent.STM (stm), single-threaded: TVars are IORefs.
module Control.Concurrent.STM (
    module Control.Monad.STM,
    TVar, newTVar, newTVarIO, readTVar, readTVarIO, writeTVar, modifyTVar,
    modifyTVar', stateTVar, swapTVar,
    TMVar, newTMVar, newEmptyTMVar, newTMVarIO, newEmptyTMVarIO, takeTMVar,
    putTMVar, readTMVar, tryTakeTMVar, tryPutTMVar, isEmptyTMVar,
    TChan, newTChan, newTChanIO, writeTChan, readTChan, tryReadTChan,
    isEmptyTChan,
    TQueue, newTQueue, newTQueueIO, writeTQueue, readTQueue, tryReadTQueue,
    isEmptyTQueue, flushTQueue
  ) where

import Control.Monad.STM
import Data.IORef

io :: IO a -> STM a
io = unsafeIOToSTM

newtype TVar a = TVar (IORef a)

instance Eq (TVar a) where
  TVar a == TVar b = a == b

newTVar :: a -> STM (TVar a)
newTVar x = io (fmap TVar (newIORef x))

newTVarIO :: a -> IO (TVar a)
newTVarIO x = fmap TVar (newIORef x)

readTVar :: TVar a -> STM a
readTVar (TVar r) = io (readIORef r)

readTVarIO :: TVar a -> IO a
readTVarIO (TVar r) = readIORef r

writeTVar :: TVar a -> a -> STM ()
writeTVar (TVar r) x = io (writeIORef r x)

modifyTVar, modifyTVar' :: TVar a -> (a -> a) -> STM ()
modifyTVar (TVar r) f = io (modifyIORef r f)
modifyTVar' (TVar r) f = io (modifyIORef' r f)

stateTVar :: TVar s -> (s -> (a, s)) -> STM a
stateTVar v f = do
  s <- readTVar v
  let (a, s') = f s
  writeTVar v s'
  return a

swapTVar :: TVar a -> a -> STM a
swapTVar v x = do { old <- readTVar v; writeTVar v x; return old }

newtype TMVar a = TMVar (TVar (Maybe a))

newTMVar :: a -> STM (TMVar a)
newTMVar x = fmap TMVar (newTVar (Just x))
newEmptyTMVar :: STM (TMVar a)
newEmptyTMVar = fmap TMVar (newTVar Nothing)
newTMVarIO :: a -> IO (TMVar a)
newTMVarIO x = fmap TMVar (newTVarIO (Just x))
newEmptyTMVarIO :: IO (TMVar a)
newEmptyTMVarIO = fmap TMVar (newTVarIO Nothing)

takeTMVar :: TMVar a -> STM a
takeTMVar (TMVar v) = readTVar v >>= maybe retry (\x -> writeTVar v Nothing >> return x)
readTMVar :: TMVar a -> STM a
readTMVar (TMVar v) = readTVar v >>= maybe retry return
putTMVar :: TMVar a -> a -> STM ()
putTMVar (TMVar v) x = readTVar v >>= maybe (writeTVar v (Just x)) (const retry)
tryTakeTMVar :: TMVar a -> STM (Maybe a)
tryTakeTMVar (TMVar v) = do { m <- readTVar v; writeTVar v Nothing; return m }
tryPutTMVar :: TMVar a -> a -> STM Bool
tryPutTMVar (TMVar v) x = readTVar v >>= maybe (writeTVar v (Just x) >> return True) (const (return False))
isEmptyTMVar :: TMVar a -> STM Bool
isEmptyTMVar (TMVar v) = fmap (maybe True (const False)) (readTVar v)

newtype TQueue a = TQueue (TVar ([a], [a]))
type TChan = TQueue

newTQueue :: STM (TQueue a)
newTQueue = fmap TQueue (newTVar ([], []))
newTQueueIO :: IO (TQueue a)
newTQueueIO = fmap TQueue (newTVarIO ([], []))
writeTQueue :: TQueue a -> a -> STM ()
writeTQueue (TQueue v) x = modifyTVar' v (\(f, b) -> (f, x : b))
tryReadTQueue :: TQueue a -> STM (Maybe a)
tryReadTQueue (TQueue v) = do
  q <- readTVar v
  case q of
    (x : f, b) -> writeTVar v (f, b) >> return (Just x)
    ([], []) -> return Nothing
    ([], b) -> case reverse b of
                 (x : f) -> writeTVar v (f, []) >> return (Just x)
                 [] -> return Nothing
readTQueue :: TQueue a -> STM a
readTQueue q = tryReadTQueue q >>= maybe retry return
isEmptyTQueue :: TQueue a -> STM Bool
isEmptyTQueue (TQueue v) = fmap (\(f, b) -> null f && null b) (readTVar v)
flushTQueue :: TQueue a -> STM [a]
flushTQueue (TQueue v) = do { (f, b) <- readTVar v; writeTVar v ([], []); return (f ++ reverse b) }

newTChan :: STM (TChan a)
newTChan = newTQueue
newTChanIO :: IO (TChan a)
newTChanIO = newTQueueIO
writeTChan :: TChan a -> a -> STM ()
writeTChan = writeTQueue
readTChan :: TChan a -> STM a
readTChan = readTQueue
tryReadTChan :: TChan a -> STM (Maybe a)
tryReadTChan = tryReadTQueue
isEmptyTChan :: TChan a -> STM Bool
isEmptyTChan = isEmptyTQueue
