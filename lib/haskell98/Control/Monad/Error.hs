-- Control.Monad.Error (mtl before 2.3, deprecated there): the Error
-- class and the ErrorT transformer, with MonadError.  Code from before
-- ExceptT (LambdaPi, 2007) uses it.
module Control.Monad.Error (
    Error(noMsg, strMsg), ErrorT(ErrorT, runErrorT), mapErrorT,
    MonadError(throwError, catchError), liftEither,
    MonadTrans(lift), MonadIO(liftIO), module Control.Monad
  ) where

import PreludeModern
import Control.Monad.Error.Class
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Control.Monad
import Monad (MonadPlus(mzero, mplus))

class Error a where
  noMsg  :: a
  strMsg :: String -> a

  noMsg    = strMsg ""
  strMsg _ = noMsg

instance Error [Char] where
  noMsg = ""
  strMsg = id

newtype ErrorT e m a = ErrorT { runErrorT :: m (Either e a) }

mapErrorT :: (m (Either e a) -> n (Either e' b)) -> ErrorT e m a -> ErrorT e' n b
mapErrorT f m = ErrorT (f (runErrorT m))

instance Monad m => Functor (ErrorT e m) where
  fmap f m = ErrorT (runErrorT m >>= \v -> return (fmap f v))

instance Monad m => Applicative (ErrorT e m) where
  pure a = ErrorT (return (Right a))
  mf <*> mx = ErrorT (runErrorT mf >>= \f -> case f of
                        Left e -> return (Left e)
                        Right g -> runErrorT mx >>= \x -> return (fmap g x))

instance Monad m => Monad (ErrorT e m) where
  return a = ErrorT (return (Right a))
  m >>= k = ErrorT (runErrorT m >>= \v -> case v of
                      Left e -> return (Left e)
                      Right a -> runErrorT (k a))

instance (Monad m, Error e) => MonadFail (ErrorT e m) where
  fail msg = ErrorT (return (Left (strMsg msg)))

instance (Monad m, Error e) => Alternative (ErrorT e m) where
  empty = ErrorT (return (Left noMsg))
  m <|> n = ErrorT (runErrorT m >>= \v -> case v of
                      Left _ -> runErrorT n
                      r -> return r)

instance (Monad m, Error e) => MonadPlus (ErrorT e m) where
  mzero = empty
  mplus = (<|>)

instance Monad m => MonadError e (ErrorT e m) where
  throwError e = ErrorT (return (Left e))
  catchError m h = ErrorT (runErrorT m >>= \v -> case v of
                             Left e -> runErrorT (h e)
                             r -> return r)

instance MonadTrans (ErrorT e) where
  lift m = ErrorT (m >>= \a -> return (Right a))

instance MonadIO m => MonadIO (ErrorT e m) where
  liftIO io = lift (liftIO io)
