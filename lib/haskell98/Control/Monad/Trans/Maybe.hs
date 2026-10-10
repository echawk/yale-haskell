-- Control.Monad.Trans.Maybe (transformers)
module Control.Monad.Trans.Maybe (
    MaybeT(MaybeT, runMaybeT), mapMaybeT, hoistMaybe
  ) where

import PreludeModern
import Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class
import Control.Monad.IO.Class

newtype MaybeT m a = MaybeT { runMaybeT :: m (Maybe a) }

mapMaybeT :: (m (Maybe a) -> n (Maybe b)) -> MaybeT m a -> MaybeT n b
mapMaybeT f m = MaybeT (f (runMaybeT m))

hoistMaybe :: Monad m => Maybe a -> MaybeT m a
hoistMaybe m = MaybeT (return m)

instance Monad m => Functor (MaybeT m) where
  fmap f m = MaybeT (runMaybeT m >>= \v -> return (fmap f v))

instance Monad m => Applicative (MaybeT m) where
  pure a = MaybeT (return (Just a))
  mf <*> mx = MaybeT (runMaybeT mf >>= \f -> case f of
                        Nothing -> return Nothing
                        Just g -> runMaybeT mx >>= \x -> return (fmap g x))

instance Monad m => Monad (MaybeT m) where
  return a = MaybeT (return (Just a))
  m >>= k = MaybeT (runMaybeT m >>= \v -> case v of
                      Nothing -> return Nothing
                      Just a -> runMaybeT (k a))

instance Monad m => Alternative (MaybeT m) where
  empty = MaybeT (return Nothing)
  m <|> n = MaybeT (runMaybeT m >>= \v -> case v of
                      Nothing -> runMaybeT n
                      Just _ -> return v)

instance Monad m => MonadPlus (MaybeT m) where
  mzero = MaybeT (return Nothing)
  m `mplus` n = m <|> n

instance Monad m => MonadFail (MaybeT m) where
  fail _ = MaybeT (return Nothing)

instance MonadTrans MaybeT where
  lift m = MaybeT (m >>= \a -> return (Just a))

instance MonadIO m => MonadIO (MaybeT m) where
  liftIO io = lift (liftIO io)
