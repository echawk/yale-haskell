-- Control.Monad.STM (stm), single-threaded (Control.Concurrent): a
-- transaction runs alone, so atomically just runs it.  retry, which
-- would wait for another thread's change, fails.
module Control.Monad.STM (
    STM, atomically, retry, orElse, check, throwSTM, catchSTM,
    unsafeIOToSTM
  ) where

import Prelude hiding (catch)
import PreludeModern
import Control.Exception (Exception, throwIO, catch)

newtype STM a = STM (IO a)

unSTM :: STM a -> IO a
unSTM (STM io) = io

instance Functor STM where
  fmap f (STM io) = STM (fmap f io)
instance Applicative STM where
  pure x = STM (return x)
  STM f <*> STM x = STM (f >>= \g -> fmap g x)
instance Monad STM where
  return x = STM (return x)
  STM m >>= k = STM (m >>= \x -> unSTM (k x))

atomically :: STM a -> IO a
atomically (STM io) = io

retry :: STM a
retry = STM (ioError (userError "thread blocked indefinitely in an STM transaction"))

orElse :: STM a -> STM a -> STM a
orElse (STM a) (STM b) = STM (a `catch` \e -> const b (e :: IOError))

check :: Bool -> STM ()
check b = if b then return () else retry

throwSTM :: Exception e => e -> STM a
throwSTM e = STM (throwIO e)

catchSTM :: Exception e => STM a -> (e -> STM a) -> STM a
catchSTM (STM a) h = STM (a `catch` \e -> unSTM (h e))

unsafeIOToSTM :: IO a -> STM a
unsafeIOToSTM = STM
