-- Control.Concurrent.STM (stm): TVars and the structures over them
-- (STMBase has the transactions).
module Control.Concurrent.STM (
    module Control.Monad.STM,
    TVar, newTVar, newTVarIO, readTVar, readTVarIO, writeTVar, modifyTVar,
    modifyTVar', stateTVar, swapTVar,
    TMVar, newTMVar, newEmptyTMVar, newTMVarIO, newEmptyTMVarIO, takeTMVar,
    putTMVar, readTMVar, tryTakeTMVar, tryPutTMVar, isEmptyTMVar,
    swapTMVar, tryReadTMVar, writeTMVar,
    TChan, newTChan, newTChanIO, writeTChan, readTChan, tryReadTChan,
    isEmptyTChan, unGetTChan, peekTChan, tryPeekTChan, newBroadcastTChan,
    newBroadcastTChanIO, dupTChan, cloneTChan,
    TQueue, newTQueue, newTQueueIO, writeTQueue, readTQueue, tryReadTQueue,
    isEmptyTQueue, flushTQueue, unGetTQueue, peekTQueue, tryPeekTQueue,
    TBQueue, newTBQueue, newTBQueueIO, writeTBQueue, readTBQueue,
    tryReadTBQueue, flushTBQueue, lengthTBQueue, isEmptyTBQueue, isFullTBQueue,
    threadWaitReadSTM, threadWaitWriteSTM
  ) where

import Control.Monad.STM
import STMBase (TVar, newTVar, newTVarIO, readTVar, readTVarIO, writeTVar)
import Control.Concurrent (forkIO, killThread, threadWaitRead, threadWaitWrite)
import System.Posix.Types (Fd)
import Numeric.Natural (Natural)

modifyTVar, modifyTVar' :: TVar a -> (a -> a) -> STM ()
modifyTVar v f = readTVar v >>= writeTVar v . f
modifyTVar' v f = do { x <- readTVar v; writeTVar v $! f x }

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
swapTMVar :: TMVar a -> a -> STM a
swapTMVar (TMVar v) new = readTVar v >>= maybe retry (\old -> writeTVar v (Just new) >> return old)
tryReadTMVar :: TMVar a -> STM (Maybe a)
tryReadTMVar (TMVar v) = readTVar v
writeTMVar :: TMVar a -> a -> STM ()
writeTMVar (TMVar v) x = writeTVar v (Just x)
isEmptyTMVar :: TMVar a -> STM Bool
isEmptyTMVar (TMVar v) = fmap (maybe True (const False)) (readTVar v)

newtype TQueue a = TQueue (TVar ([a], [a]))

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

-- the next value to read
unGetTQueue :: TQueue a -> a -> STM ()
unGetTQueue (TQueue v) x = modifyTVar' v (\(f, b) -> (x : f, b))
tryPeekTQueue :: TQueue a -> STM (Maybe a)
tryPeekTQueue q = do
  m <- tryReadTQueue q
  case m of
    Just x -> do { unGetTQueue q x; return (Just x) }
    Nothing -> return Nothing
peekTQueue :: TQueue a -> STM a
peekTQueue q = tryPeekTQueue q >>= maybe retry return

-- A channel as stm's: a linked list of TVars, a read end and a write
-- end; a duplicate has a read end of its own.
type TVarList a = TVar (TList a)
data TList a = TNil | TCons a (TVarList a)

data TChan a = TChan (TVar (TVarList a)) (TVar (TVarList a))

instance Eq (TChan a) where
  TChan a _ == TChan b _ = a == b

newTChan :: STM (TChan a)
newTChan = do
  hole <- newTVar TNil
  r <- newTVar hole
  w <- newTVar hole
  return (TChan r w)

newTChanIO :: IO (TChan a)
newTChanIO = atomically newTChan

-- written to only: a reader is made with dupTChan
newBroadcastTChan :: STM (TChan a)
newBroadcastTChan = do
  hole <- newTVar TNil
  r <- newTVar (error "reading from a TChan created by newBroadcastTChan; use dupTChan first")
  w <- newTVar hole
  return (TChan r w)

newBroadcastTChanIO :: IO (TChan a)
newBroadcastTChanIO = atomically newBroadcastTChan

writeTChan :: TChan a -> a -> STM ()
writeTChan (TChan _ w) a = do
  listend <- readTVar w
  newend <- newTVar TNil
  writeTVar listend (TCons a newend)
  writeTVar w newend

readTChan :: TChan a -> STM a
readTChan c = tryReadTChan c >>= maybe retry return

tryReadTChan :: TChan a -> STM (Maybe a)
tryReadTChan (TChan r _) = do
  listhead <- readTVar r
  h <- readTVar listhead
  case h of
    TNil -> return Nothing
    TCons a rest -> writeTVar r rest >> return (Just a)

peekTChan :: TChan a -> STM a
peekTChan c = tryPeekTChan c >>= maybe retry return

tryPeekTChan :: TChan a -> STM (Maybe a)
tryPeekTChan (TChan r _) = do
  listhead <- readTVar r
  h <- readTVar listhead
  return (case h of { TNil -> Nothing; TCons a _ -> Just a })

unGetTChan :: TChan a -> a -> STM ()
unGetTChan (TChan r _) a = do
  listhead <- readTVar r
  newhead <- newTVar (TCons a listhead)
  writeTVar r newhead

isEmptyTChan :: TChan a -> STM Bool
isEmptyTChan (TChan r _) = do
  listhead <- readTVar r
  h <- readTVar listhead
  return (case h of { TNil -> True; TCons _ _ -> False })

-- a reader of what is written from now on
dupTChan :: TChan a -> STM (TChan a)
dupTChan (TChan _ w) = do
  hole <- readTVar w
  r <- newTVar hole
  return (TChan r w)

-- a reader of what the channel's reader has still to read, too
cloneTChan :: TChan a -> STM (TChan a)
cloneTChan (TChan r w) = do
  readpos <- readTVar r
  r' <- newTVar readpos
  return (TChan r' w)

-- A bounded queue: writeTBQueue retries while it holds its capacity.
data TBQueue a = TBQueue (TQueue a) (TVar Int) Int

newTBQueue :: Natural -> STM (TBQueue a)
newTBQueue n = do { q <- newTQueue; c <- newTVar 0; return (TBQueue q c (fromIntegral n)) }
newTBQueueIO :: Natural -> IO (TBQueue a)
newTBQueueIO n = do { q <- newTQueueIO; c <- newTVarIO 0; return (TBQueue q c (fromIntegral n)) }
writeTBQueue :: TBQueue a -> a -> STM ()
writeTBQueue (TBQueue q c cap) x = do
  n <- readTVar c
  if n >= cap then retry else do { writeTVar c (n + 1); writeTQueue q x }
readTBQueue :: TBQueue a -> STM a
readTBQueue (TBQueue q c _) = do { x <- readTQueue q; modifyTVar' c (subtract 1); return x }
tryReadTBQueue :: TBQueue a -> STM (Maybe a)
tryReadTBQueue (TBQueue q c _) = do
  r <- tryReadTQueue q
  case r of
    Just _ -> modifyTVar' c (subtract 1)
    Nothing -> return ()
  return r
flushTBQueue :: TBQueue a -> STM [a]
flushTBQueue (TBQueue q c _) = do { writeTVar c 0; flushTQueue q }
lengthTBQueue :: TBQueue a -> STM Natural
lengthTBQueue (TBQueue _ c _) = fmap fromIntegral (readTVar c)
isEmptyTBQueue :: TBQueue a -> STM Bool
isEmptyTBQueue (TBQueue q _ _) = isEmptyTQueue q
isFullTBQueue :: TBQueue a -> STM Bool
isFullTBQueue (TBQueue _ c cap) = fmap (>= cap) (readTVar c)

-- GHC.Conc's (Control.Concurrent's in base): an STM action that waits
-- until the descriptor is ready, and an action that stops waiting.  A
-- thread waits and sets a TVar.
threadWaitReadSTM, threadWaitWriteSTM :: Fd -> IO (STM (), IO ())
threadWaitReadSTM = threadWaitSTM threadWaitRead
threadWaitWriteSTM = threadWaitSTM threadWaitWrite

threadWaitSTM :: (Fd -> IO ()) -> Fd -> IO (STM (), IO ())
threadWaitSTM wait fd = do
  ready <- newTVarIO False
  t <- forkIO (wait fd >> atomically (writeTVar ready True))
  return (readTVar ready >>= \ r -> if r then return () else retry,
          killThread t)
