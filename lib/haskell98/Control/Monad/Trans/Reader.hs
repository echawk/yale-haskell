-- Control.Monad.Trans.Reader (transformers)
module Control.Monad.Trans.Reader (
    ReaderT(ReaderT, runReaderT), Reader, runReader, mapReaderT, withReaderT,
    reader, ask, local, asks
  ) where

import PreludeModern
import Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Data.Functor.Identity

newtype ReaderT r m a = ReaderT { runReaderT :: r -> m a }

type Reader r = ReaderT r Identity

runReader :: Reader r a -> r -> a
runReader m r = runIdentity (runReaderT m r)

mapReaderT :: (m a -> n b) -> ReaderT r m a -> ReaderT r n b
mapReaderT f m = ReaderT (\r -> f (runReaderT m r))

withReaderT :: (r' -> r) -> ReaderT r m a -> ReaderT r' m a
withReaderT f m = ReaderT (\r -> runReaderT m (f r))

instance Monad m => Functor (ReaderT r m) where
  fmap f m = ReaderT (\r -> runReaderT m r >>= \a -> return (f a))

instance Monad m => Applicative (ReaderT r m) where
  pure a = ReaderT (\_ -> return a)
  mf <*> mx = ReaderT (\r -> runReaderT mf r >>= \f ->
                             runReaderT mx r >>= \x -> return (f x))

instance Monad m => Monad (ReaderT r m) where
  return a = ReaderT (\_ -> return a)
  m >>= k = ReaderT (\r -> runReaderT m r >>= \a -> runReaderT (k a) r)

instance MonadPlus m => Alternative (ReaderT r m) where
  empty = ReaderT (\_ -> mzero)
  m <|> n = ReaderT (\r -> runReaderT m r `mplus` runReaderT n r)

instance MonadPlus m => MonadPlus (ReaderT r m) where
  mzero = ReaderT (\_ -> mzero)
  m `mplus` n = ReaderT (\r -> runReaderT m r `mplus` runReaderT n r)

instance MonadFail m => MonadFail (ReaderT r m) where
  fail msg = ReaderT (\_ -> fail msg)

instance MonadTrans (ReaderT r) where
  lift m = ReaderT (\_ -> m)

instance MonadIO m => MonadIO (ReaderT r m) where
  liftIO io = lift (liftIO io)

reader :: Monad m => (r -> a) -> ReaderT r m a
reader f = ReaderT (\r -> return (f r))

ask :: Monad m => ReaderT r m r
ask = ReaderT return

local :: (r -> r) -> ReaderT r m a -> ReaderT r m a
local f m = ReaderT (\r -> runReaderT m (f r))

asks :: Monad m => (r -> a) -> ReaderT r m a
asks f = ReaderT (\r -> return (f r))
