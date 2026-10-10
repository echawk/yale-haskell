-- Control.Monad.Trans.Writer.Lazy (transformers)
module Control.Monad.Trans.Writer.Lazy (
    WriterT(WriterT, runWriterT), Writer, runWriter, execWriter, execWriterT,
    mapWriterT, writer, tell, listen, pass, censor
  ) where

import PreludeModern
import Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Data.Functor.Identity

newtype WriterT w m a = WriterT { runWriterT :: m (a, w) }

type Writer w = WriterT w Identity

runWriter :: Writer w a -> (a, w)
runWriter m = runIdentity (runWriterT m)

execWriter :: Writer w a -> w
execWriter m = snd (runWriter m)

execWriterT :: Monad m => WriterT w m a -> m w
execWriterT m = runWriterT m >>= \ ~(_, w) -> return w

mapWriterT :: (m (a, w) -> n (b, w')) -> WriterT w m a -> WriterT w' n b
mapWriterT f m = WriterT (f (runWriterT m))

instance Monad m => Functor (WriterT w m) where
  fmap f m = WriterT (runWriterT m >>= \ ~(a, w) -> return (f a, w))

instance (Monoid w, Monad m) => Applicative (WriterT w m) where
  pure a = WriterT (return (a, mempty))
  mf <*> mx = WriterT (runWriterT mf >>= \ ~(f, w) ->
                       runWriterT mx >>= \ ~(x, w') -> return (f x, w `mappend` w'))

instance (Monoid w, Monad m) => Monad (WriterT w m) where
  return a = WriterT (return (a, mempty))
  m >>= k = WriterT (runWriterT m >>= \ ~(a, w) ->
                     runWriterT (k a) >>= \ ~(b, w') -> return (b, w `mappend` w'))

instance (Monoid w, MonadFail m) => MonadFail (WriterT w m) where
  fail msg = WriterT (fail msg)

instance Monoid w => MonadTrans (WriterT w) where
  lift m = WriterT (m >>= \a -> return (a, mempty))

instance (Monoid w, MonadIO m) => MonadIO (WriterT w m) where
  liftIO io = lift (liftIO io)

writer :: Monad m => (a, w) -> WriterT w m a
writer aw = WriterT (return aw)

tell :: Monad m => w -> WriterT w m ()
tell w = WriterT (return ((), w))

listen :: Monad m => WriterT w m a -> WriterT w m (a, w)
listen m = WriterT (runWriterT m >>= \ ~(a, w) -> return ((a, w), w))

pass :: Monad m => WriterT w m (a, w -> w) -> WriterT w m a
pass m = WriterT (runWriterT m >>= \ ~((a, f), w) -> return (a, f w))

censor :: Monad m => (w -> w) -> WriterT w m a -> WriterT w m a
censor f m = WriterT (runWriterT m >>= \ ~(a, w) -> return (a, f w))
