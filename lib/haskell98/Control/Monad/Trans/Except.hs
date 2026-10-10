-- Control.Monad.Trans.Except (transformers)
module Control.Monad.Trans.Except (
    ExceptT(ExceptT), Except, except, runExcept, runExceptT, mapExceptT,
    withExceptT, throwE, catchE
  ) where

import PreludeModern
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Data.Functor.Identity

newtype ExceptT e m a = ExceptT (m (Either e a))

type Except e = ExceptT e Identity

runExceptT :: ExceptT e m a -> m (Either e a)
runExceptT (ExceptT m) = m

except :: Monad m => Either e a -> ExceptT e m a
except m = ExceptT (return m)

runExcept :: Except e a -> Either e a
runExcept m = runIdentity (runExceptT m)

mapExceptT :: (m (Either e a) -> n (Either e' b)) -> ExceptT e m a -> ExceptT e' n b
mapExceptT f m = ExceptT (f (runExceptT m))

withExceptT :: Monad m => (e -> e') -> ExceptT e m a -> ExceptT e' m a
withExceptT f m = ExceptT (runExceptT m >>= \v -> return (either (Left . f) Right v))

instance Monad m => Functor (ExceptT e m) where
  fmap f m = ExceptT (runExceptT m >>= \v -> return (fmap f v))

instance Monad m => Applicative (ExceptT e m) where
  pure a = ExceptT (return (Right a))
  mf <*> mx = ExceptT (runExceptT mf >>= \f -> case f of
                         Left e -> return (Left e)
                         Right g -> runExceptT mx >>= \x -> return (fmap g x))

instance Monad m => Monad (ExceptT e m) where
  return a = ExceptT (return (Right a))
  m >>= k = ExceptT (runExceptT m >>= \v -> case v of
                       Left e -> return (Left e)
                       Right a -> runExceptT (k a))

instance MonadFail m => MonadFail (ExceptT e m) where
  fail msg = ExceptT (fail msg)

instance MonadTrans (ExceptT e) where
  lift m = ExceptT (m >>= \a -> return (Right a))

instance MonadIO m => MonadIO (ExceptT e m) where
  liftIO io = lift (liftIO io)

throwE :: Monad m => e -> ExceptT e m a
throwE e = ExceptT (return (Left e))

catchE :: Monad m => ExceptT e m a -> (e -> ExceptT e' m a) -> ExceptT e' m a
catchE m h = ExceptT (runExceptT m >>= \v -> case v of
                        Left e -> runExceptT (h e)
                        Right a -> return (Right a))
