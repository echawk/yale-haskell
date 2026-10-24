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
import qualified Control.Monad.Trans.RWS.Lazy as RWSL
import qualified Control.Monad.Trans.RWS.Strict as RWSS
import qualified Control.Monad.Trans.Writer.Strict as WS
import qualified Control.Monad.Trans.Writer.Lazy as WL
import Control.Monad.Trans.Maybe (MaybeT(MaybeT), runMaybeT)
import Control.Monad.Trans.Identity (IdentityT(IdentityT), runIdentityT)
import System.IO.Error (catchIOError)

class Monad m => MonadError e m | m -> e where
  throwError :: e -> m a
  catchError :: m a -> (e -> m a) -> m a

liftEither :: MonadError e m => Either e a -> m a
liftEither = either throwError return

-- (Nothing, its error ())
instance MonadError () Maybe where
  throwError () = Nothing
  catchError Nothing h = h ()
  catchError r _ = r

instance MonadError IOError IO where
  throwError = ioError
  catchError = catchIOError

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

instance (Monoid w, Monad m, MonadError e m) => MonadError e (RWSL.RWST r w s m) where
  throwError e = lift (throwError e)
  catchError m h = RWSL.RWST (\r s -> catchError (RWSL.runRWST m r s) (\e -> RWSL.runRWST (h e) r s))

instance (Monoid w, Monad m, MonadError e m) => MonadError e (RWSS.RWST r w s m) where
  throwError e = lift (throwError e)
  catchError m h = RWSS.RWST (\r s -> catchError (RWSS.runRWST m r s) (\e -> RWSS.runRWST (h e) r s))

instance (Monoid w, Monad m, MonadError e m) => MonadError e (WS.WriterT w m) where
  throwError e = lift (throwError e)
  catchError m h = WS.WriterT (catchError (WS.runWriterT m) (\e -> WS.runWriterT (h e)))

instance (Monoid w, Monad m, MonadError e m) => MonadError e (WL.WriterT w m) where
  throwError e = lift (throwError e)
  catchError m h = WL.WriterT (catchError (WL.runWriterT m) (\e -> WL.runWriterT (h e)))

instance (Monad m, MonadError e m) => MonadError e (MaybeT m) where
  throwError e = lift (throwError e)
  catchError m h = MaybeT (catchError (runMaybeT m) (\e -> runMaybeT (h e)))

instance MonadError e m => MonadError e (IdentityT m) where
  throwError e = lift (throwError e)
  catchError m h = IdentityT (catchError (runIdentityT m) (\e -> runIdentityT (h e)))
