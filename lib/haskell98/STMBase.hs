-- STMBase: STM and TVar, for Control.Monad.STM and Control.Concurrent.STM.
-- A transaction runs holding the runtime's STM lock
-- (src/base/concurrent-runtime.lisp), so transactions run one at a time;
-- it logs how to undo its TVar writes, for retry, for an exception, and
-- for orElse's and catchSTM's first branch.  retry undoes the
-- transaction and waits for another one to commit, then runs it again.
module STMBase (
    STM, atomically, retry, orElse, check, throwSTM, catchSTM,
    unsafeIOToSTM, TVar, newTVar, newTVarIO, readTVar, readTVarIO,
    writeTVar
  ) where

import Prelude hiding (catch)
import PreludeModern (Applicative(..), Alternative(..))
import Control.Exception (Exception(..), SomeException(..), throwIO, try,
                          mask, BlockedIndefinitelyOnSTM(..))
import Monad (MonadPlus)
import Data.IORef
import BasePrims (Exc)
import ConcurrentPrims (primSTMLock, primSTMUnlock, primSTMWait)

-- the transaction's undo actions, the latest first
type Log = IORef [IO ()]

newtype STM a = STM (Log -> IO a)

runSTM :: STM a -> Log -> IO a
runSTM (STM f) = f

instance Functor STM where
  fmap f (STM m) = STM (\l -> fmap f (m l))
instance Applicative STM where
  pure x = STM (\_ -> return x)
  STM f <*> STM x = STM (\l -> f l >>= \g -> fmap g (x l))
instance Monad STM where
  return = pure
  STM m >>= k = STM (\l -> m l >>= \x -> runSTM (k x) l)

-- (as stm's: empty is retry, <|> is orElse)
instance Alternative STM where
  empty = retry
  (<|>) = orElse

instance MonadPlus STM

data Retry = Retry

instance Show Retry where
  showsPrec _ _ = showString "<<retry>>"

instance Exception Retry

isRetry :: SomeException -> Bool
isRetry e = case fromException e of
  Just Retry -> True
  Nothing -> False

undo :: Log -> IO ()
undo l = readIORef l >>= sequence_

blocked :: Exc
blocked = case toException BlockedIndefinitelyOnSTM of SomeException e -> e

atomically :: STM a -> IO a
atomically (STM f) = mask $ \restore -> do
  primSTMLock
  r <- try (restore run)
  case r of
    Left e -> primSTMUnlock False >> throwIO (e :: SomeException)
    Right (x, wrote) -> primSTMUnlock wrote >> return x
  where
    run = do
      l <- newIORef []
      r <- try (f l)
      case r of
        Right x -> do
          us <- readIORef l
          return (x, not (null us))
        Left e
          | isRetry e -> undo l >> primSTMWait blocked >> run
          | otherwise -> undo l >> throwIO e

retry :: STM a
retry = STM (\_ -> throwIO Retry)

-- the first branch's writes join the transaction's
orElse :: STM a -> STM a -> STM a
orElse (STM a) (STM b) = STM $ \l -> do
  inner <- newIORef []
  r <- try (a inner)
  case r of
    Right x -> joinLog inner l >> return x
    Left e
      | isRetry e -> undo inner >> b l
      | otherwise -> joinLog inner l >> throwIO e

joinLog :: Log -> Log -> IO ()
joinLog inner l = do
  us <- readIORef inner
  modifyIORef l (us ++)

check :: Bool -> STM ()
check b = if b then return () else retry

throwSTM :: Exception e => e -> STM a
throwSTM e = STM (\_ -> throwIO e)

-- the action's writes are undone before the handler runs
catchSTM :: Exception e => STM a -> (e -> STM a) -> STM a
catchSTM (STM a) h = STM $ \l -> do
  inner <- newIORef []
  r <- try (a inner)
  case r of
    Right x -> joinLog inner l >> return x
    Left e -> case (if isRetry e then Nothing else fromException e) of
      Just e' -> undo inner >> runSTM (h e') l
      Nothing -> joinLog inner l >> throwIO e

unsafeIOToSTM :: IO a -> STM a
unsafeIOToSTM io = STM (\_ -> io)

newtype TVar a = TVar (IORef a)

instance Eq (TVar a) where
  TVar a == TVar b = a == b

newTVar :: a -> STM (TVar a)
newTVar x = unsafeIOToSTM (newTVarIO x)

newTVarIO :: a -> IO (TVar a)
newTVarIO x = fmap TVar (newIORef x)

readTVar :: TVar a -> STM a
readTVar (TVar r) = unsafeIOToSTM (readIORef r)

readTVarIO :: TVar a -> IO a
readTVarIO (TVar r) = readIORef r

writeTVar :: TVar a -> a -> STM ()
writeTVar (TVar r) x = STM $ \l -> do
  old <- readIORef r
  modifyIORef l (writeIORef r old :)
  writeIORef r x
