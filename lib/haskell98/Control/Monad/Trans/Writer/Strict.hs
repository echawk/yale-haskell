-- Control.Monad.Trans.Writer.Strict (transformers): as .Lazy, with the
-- result pairs matched strictly.
module Control.Monad.Trans.Writer.Strict (
    WriterT(WriterT, runWriterT), Writer, runWriter, execWriter, execWriterT,
    mapWriterT, mapWriter, writer, tell, listen, pass, censor,
    liftCallCC, liftCatch
  ) where

import Control.Monad.Fix (MonadFix(mfix))
import Data.Functor.Contravariant (Contravariant(contramap))
import Control.Monad.Signatures
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
execWriterT m = runWriterT m >>= \(_, w) -> return w

mapWriter :: ((a, w) -> (b, w')) -> Writer w a -> Writer w' b
mapWriter f = mapWriterT (Identity . f . runIdentity)

mapWriterT :: (m (a, w) -> n (b, w')) -> WriterT w m a -> WriterT w' n b
mapWriterT f m = WriterT (f (runWriterT m))

instance Functor m => Functor (WriterT w m) where
  fmap f m = WriterT (fmap (\(a, w) -> (f a, w)) (runWriterT m))

instance (Monoid w, Monad m) => Applicative (WriterT w m) where
  pure a = WriterT (return (a, mempty))
  mf <*> mx = WriterT (runWriterT mf >>= \(f, w) ->
                       runWriterT mx >>= \(x, w') -> return (f x, w `mappend` w'))

instance (Monoid w, Monad m) => Monad (WriterT w m) where
  return a = WriterT (return (a, mempty))
  m >>= k = WriterT (runWriterT m >>= \(a, w) ->
                     runWriterT (k a) >>= \(b, w') -> return (b, w `mappend` w'))

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
listen m = WriterT (runWriterT m >>= \(a, w) -> return ((a, w), w))

pass :: Monad m => WriterT w m (a, w -> w) -> WriterT w m a
pass m = WriterT (runWriterT m >>= \((a, f), w) -> return (a, f w))

censor :: Monad m => (w -> w) -> WriterT w m a -> WriterT w m a
censor f m = WriterT (runWriterT m >>= \(a, w) -> return (a, f w))

-- Lifting other operations through WriterT (transformers)
liftCallCC :: Monoid w => CallCC m (a, w) (b, w) -> CallCC (WriterT w m) a b
liftCallCC callCC f = WriterT $ callCC $ \c ->
  runWriterT (f (\a -> WriterT $ c (a, mempty)))

liftCatch :: Catch e m (a, w) -> Catch e (WriterT w m) a
liftCatch catchE m h = WriterT $ runWriterT m `catchE` \e -> runWriterT (h e)

-- transformers' (the transformed monad contravariant)
instance Contravariant m => Contravariant (WriterT w m) where
  contramap f = mapWriterT $ contramap $ \(a, w) -> (f a, w)

-- transformers' Foldable and Traversable
instance Foldable f => Foldable (WriterT w f) where
  foldMap f = foldMap (f . fst) . runWriterT
instance Traversable f => Traversable (WriterT w f) where
  traverse f = fmap WriterT . traverse (\(a, b) -> fmap (\c -> (c, b)) (f a)) . runWriterT

instance (Monoid w, MonadFix m) => MonadFix (WriterT w m) where
  mfix m = WriterT (mfix (\ ~(a, _) -> runWriterT (m a)))
