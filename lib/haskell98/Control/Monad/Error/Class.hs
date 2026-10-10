-- Control.Monad.Error.Class (mtl): MonadError, with instances for Either
-- and the transformers' monads.
module Control.Monad.Error.Class (MonadError(throwError, catchError), liftEither) where

import PreludeModern
import Control.Monad.Trans.Class
import qualified Control.Monad.Trans.Except as E
import Control.Monad.Trans.Except (ExceptT)
import qualified Control.Monad.Trans.State.Lazy as Lazy
import qualified Control.Monad.Trans.State.Strict as Strict
import Control.Monad.Trans.Reader (ReaderT(ReaderT), runReaderT)

class Monad m => MonadError e m | m -> e where
  throwError :: e -> m a
  catchError :: m a -> (e -> m a) -> m a

liftEither :: MonadError e m => Either e a -> m a
liftEither = either throwError return

instance MonadError e (Either e) where
  throwError = Left
  catchError (Left e) h = h e
  catchError r _ = r

instance Monad m => MonadError e (ExceptT e m) where
  throwError = E.throwE
  catchError = E.catchE

instance (Monad m, MonadError e m) => MonadError e (ReaderT r m) where
  throwError e = lift (throwError e)
  catchError m h = ReaderT (\r -> catchError (runReaderT m r) (\e -> runReaderT (h e) r))

instance (Monad m, MonadError e m) => MonadError e (Lazy.StateT s m) where
  throwError e = lift (throwError e)
  catchError m h = Lazy.StateT (\s -> catchError (Lazy.runStateT m s)
                                        (\e -> Lazy.runStateT (h e) s))

instance (Monad m, MonadError e m) => MonadError e (Strict.StateT s m) where
  throwError e = lift (throwError e)
  catchError m h = Strict.StateT (\s -> catchError (Strict.runStateT m s)
                                          (\e -> Strict.runStateT (h e) s))
