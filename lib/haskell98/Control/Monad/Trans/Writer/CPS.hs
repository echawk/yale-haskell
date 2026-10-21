-- Control.Monad.Trans.Writer.CPS (transformers): a writer that adds to
-- its output as it goes (in the style of a state), so it does not build
-- up thunks as the lazy and strict writers can.
module Control.Monad.Trans.Writer.CPS (
    Writer, writer, runWriter, execWriter, mapWriter,
    WriterT, writerT, runWriterT, execWriterT, mapWriterT,
    tell, listen, listens, pass, censor
  ) where

import Control.Monad.Fix (MonadFix(mfix))
import PreludeModern
import Control.Applicative (Alternative(empty, (<|>)))
import Control.Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class (MonadTrans(lift))
import Control.Monad.IO.Class (MonadIO(liftIO))
import Data.Functor.Identity (Identity(Identity), runIdentity)

newtype WriterT w m a = WriterT { unWriterT :: w -> m (a, w) }

type Writer w = WriterT w Identity

writerT :: (Functor m, Monoid w) => m (a, w) -> WriterT w m a
writerT f = WriterT (\w -> fmap (\(a, w') -> let wt = w `mappend` w' in wt `seq` (a, wt)) f)

runWriterT :: Monoid w => WriterT w m a -> m (a, w)
runWriterT m = unWriterT m mempty

execWriterT :: (Monad m, Monoid w) => WriterT w m a -> m w
execWriterT m = do { (_, w) <- runWriterT m; return w }

mapWriterT :: (Monad n, Monoid w, Monoid w') => (m (a, w) -> n (b, w')) -> WriterT w m a -> WriterT w' n b
mapWriterT f m = WriterT (\w -> do
  (a, w') <- f (runWriterT m)
  let wt = w `mappend` w'
  wt `seq` return (a, wt))

writer :: (Monoid w, Monad m) => (a, w) -> WriterT w m a
writer (a, w') = WriterT (\w -> let wt = w `mappend` w' in wt `seq` return (a, wt))

runWriter :: Monoid w => Writer w a -> (a, w)
runWriter = runIdentity . runWriterT

execWriter :: Monoid w => Writer w a -> w
execWriter = runIdentity . execWriterT

mapWriter :: (Monoid w, Monoid w') => ((a, w) -> (b, w')) -> Writer w a -> Writer w' b
mapWriter f = mapWriterT (Identity . f . runIdentity)

instance Functor m => Functor (WriterT w m) where
  fmap f m = WriterT (\w -> fmap (\(a, w') -> (f a, w')) (unWriterT m w))

instance (Functor m, Monad m) => Applicative (WriterT w m) where
  pure a = WriterT (\w -> return (a, w))
  mf <*> mx = WriterT (\w -> do
    (f, w') <- unWriterT mf w
    (x, w'') <- unWriterT mx w'
    return (f x, w''))

instance (Functor m, MonadPlus m) => Alternative (WriterT w m) where
  empty = WriterT (const mzero)
  m <|> n = WriterT (\w -> unWriterT m w `mplus` unWriterT n w)

instance Monad m => Monad (WriterT w m) where
  return = pure
  m >>= k = WriterT (\w -> do
    (a, w') <- unWriterT m w
    unWriterT (k a) w')

instance MonadFail m => MonadFail (WriterT w m) where
  fail msg = WriterT (\_ -> fail msg)

instance (Functor m, MonadPlus m) => MonadPlus (WriterT w m) where
  mzero = empty
  mplus = (<|>)

instance MonadTrans (WriterT w) where
  lift m = WriterT (\w -> do { a <- m; return (a, w) })

instance MonadIO m => MonadIO (WriterT w m) where
  liftIO = lift . liftIO

tell :: (Monoid w, Monad m) => w -> WriterT w m ()
tell w = writer ((), w)

listen :: (Monoid w, Monad m) => WriterT w m a -> WriterT w m (a, w)
listen = listens id

listens :: (Monoid w, Monad m) => (w -> b) -> WriterT w m a -> WriterT w m (a, b)
listens f m = WriterT (\w -> do
  (a, w') <- runWriterT m
  let wt = w `mappend` w'
  wt `seq` return ((a, f w'), wt))

pass :: (Monoid w, Monoid w', Monad m) => WriterT w m (a, w -> w') -> WriterT w' m a
pass m = WriterT (\w -> do
  ((a, f), w') <- runWriterT m
  let wt = w `mappend` f w'
  wt `seq` return (a, wt))

censor :: (Monoid w, Monad m) => (w -> w) -> WriterT w m a -> WriterT w m a
censor f m = WriterT (\w -> do
  (a, w') <- runWriterT m
  let wt = w `mappend` f w'
  wt `seq` return (a, wt))

instance MonadFix m => MonadFix (WriterT w m) where
  mfix f = WriterT (\w -> mfix (\ ~(a, _) -> unWriterT (f a) w))
