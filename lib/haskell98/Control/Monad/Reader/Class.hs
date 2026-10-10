-- Control.Monad.Reader.Class (mtl): MonadReader, with instances for the
-- transformers' monads.
module Control.Monad.Reader.Class (MonadReader(ask, local, reader), asks) where

import PreludeModern
import Control.Monad.Trans.Class
import qualified Control.Monad.Trans.Reader as R
import Control.Monad.Trans.Reader (ReaderT)
import qualified Control.Monad.Trans.State.Lazy as Lazy
import qualified Control.Monad.Trans.State.Strict as Strict
import Control.Monad.Trans.Writer.Lazy (WriterT(WriterT), runWriterT)
import Control.Monad.Trans.Maybe (MaybeT(MaybeT), runMaybeT)
import Control.Monad.Trans.Except (ExceptT(ExceptT), runExceptT)

class Monad m => MonadReader r m | m -> r where
  ask    :: m r
  local  :: (r -> r) -> m a -> m a
  reader :: (r -> a) -> m a

asks :: MonadReader r m => (r -> a) -> m a
asks f = reader f

instance Monad m => MonadReader r (ReaderT r m) where
  ask = R.ask
  local = R.local
  reader = R.reader

instance MonadReader r ((->) r) where
  ask = id
  local f m = m . f
  reader f = f

instance (Monad m, MonadReader r m) => MonadReader r (Lazy.StateT s m) where
  ask = lift ask
  local f m = Lazy.StateT (\s -> local f (Lazy.runStateT m s))
  reader f = lift (reader f)

instance (Monad m, MonadReader r m) => MonadReader r (Strict.StateT s m) where
  ask = lift ask
  local f m = Strict.StateT (\s -> local f (Strict.runStateT m s))
  reader f = lift (reader f)

instance (Monoid w, Monad m, MonadReader r m) => MonadReader r (WriterT w m) where
  ask = lift ask
  local f m = WriterT (local f (runWriterT m))
  reader f = lift (reader f)

instance (Monad m, MonadReader r m) => MonadReader r (MaybeT m) where
  ask = lift ask
  local f m = MaybeT (local f (runMaybeT m))
  reader f = lift (reader f)

instance (Monad m, MonadReader r m) => MonadReader r (ExceptT e m) where
  ask = lift ask
  local f m = ExceptT (local f (runExceptT m))
  reader f = lift (reader f)
