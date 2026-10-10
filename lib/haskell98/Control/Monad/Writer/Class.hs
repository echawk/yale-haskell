-- Control.Monad.Writer.Class (mtl): MonadWriter, with instances for the
-- transformers' monads.
module Control.Monad.Writer.Class (
    MonadWriter(writer, tell, listen, pass), listens, censor
  ) where

import PreludeModern
import Control.Monad.Trans.Class
import qualified Control.Monad.Trans.Writer.Lazy as W
import Control.Monad.Trans.Writer.Lazy (WriterT)
import qualified Control.Monad.Trans.State.Lazy as Lazy
import qualified Control.Monad.Trans.State.Strict as Strict
import Control.Monad.Trans.Reader (ReaderT(ReaderT), runReaderT)
import Control.Monad.Trans.Maybe (MaybeT(MaybeT), runMaybeT)

class (Monoid w, Monad m) => MonadWriter w m | m -> w where
  writer :: (a, w) -> m a
  tell   :: w -> m ()
  listen :: m a -> m (a, w)
  pass   :: m (a, w -> w) -> m a

listens :: MonadWriter w m => (w -> b) -> m a -> m (a, b)
listens f m = listen m >>= \(a, w) -> return (a, f w)

censor :: MonadWriter w m => (w -> w) -> m a -> m a
censor f m = pass (m >>= \a -> return (a, f))

instance (Monoid w, Monad m) => MonadWriter w (WriterT w m) where
  writer = W.writer
  tell = W.tell
  listen = W.listen
  pass = W.pass

instance (Monad m, MonadWriter w m) => MonadWriter w (ReaderT r m) where
  writer aw = lift (writer aw)
  tell w = lift (tell w)
  listen m = ReaderT (\r -> listen (runReaderT m r))
  pass m = ReaderT (\r -> pass (runReaderT m r))

instance (Monad m, MonadWriter w m) => MonadWriter w (Lazy.StateT s m) where
  writer aw = lift (writer aw)
  tell w = lift (tell w)
  listen m = Lazy.StateT (\s -> listen (Lazy.runStateT m s) >>= \((a, s'), w) ->
                                return ((a, w), s'))
  pass m = Lazy.StateT (\s -> pass (Lazy.runStateT m s >>= \((a, f), s') ->
                                    return ((a, s'), f)))

instance (Monad m, MonadWriter w m) => MonadWriter w (Strict.StateT s m) where
  writer aw = lift (writer aw)
  tell w = lift (tell w)
  listen m = Strict.StateT (\s -> listen (Strict.runStateT m s) >>= \((a, s'), w) ->
                                  return ((a, w), s'))
  pass m = Strict.StateT (\s -> pass (Strict.runStateT m s >>= \((a, f), s') ->
                                      return ((a, s'), f)))

instance (Monad m, MonadWriter w m) => MonadWriter w (MaybeT m) where
  writer aw = lift (writer aw)
  tell w = lift (tell w)
  listen m = MaybeT (listen (runMaybeT m) >>= \(v, w) -> return (fmap (\a -> (a, w)) v))
  pass m = MaybeT (pass (runMaybeT m >>= \v -> return (case v of
                     Nothing -> (Nothing, id)
                     Just (a, f) -> (Just a, f))))
