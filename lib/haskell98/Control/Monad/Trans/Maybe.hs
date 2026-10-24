-- Control.Monad.Trans.Maybe (transformers)
module Control.Monad.Trans.Maybe (
    MaybeT(MaybeT, runMaybeT), mapMaybeT, hoistMaybe,
    maybeToExceptT, exceptToMaybeT,
    liftCallCC, liftCatch, liftListen, liftPass
  ) where

import Control.Monad.Fix (MonadFix(mfix))
import Data.Functor.Contravariant (Contravariant(contramap))
import Control.Monad.Signatures
import PreludeModern
import Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Control.Monad.Trans.Except (ExceptT(ExceptT), runExceptT)

newtype MaybeT m a = MaybeT { runMaybeT :: m (Maybe a) }

mapMaybeT :: (m (Maybe a) -> n (Maybe b)) -> MaybeT m a -> MaybeT n b
mapMaybeT f m = MaybeT (f (runMaybeT m))

hoistMaybe :: Monad m => Maybe a -> MaybeT m a
hoistMaybe m = MaybeT (return m)

instance Functor m => Functor (MaybeT m) where
  fmap f m = MaybeT (fmap (\v -> fmap f v) (runMaybeT m))

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

-- Lifting other operations through MaybeT (transformers)
liftCallCC :: CallCC m (Maybe a) (Maybe b) -> CallCC (MaybeT m) a b
liftCallCC callCC f = MaybeT $ callCC $ \c -> runMaybeT (f (MaybeT . c . Just))

liftCatch :: Catch e m (Maybe a) -> Catch e (MaybeT m) a
liftCatch f m h = MaybeT $ f (runMaybeT m) (runMaybeT . h)

liftListen :: Monad m => Listen w m (Maybe a) -> Listen w (MaybeT m) a
liftListen listen = mapMaybeT $ \m -> do
  (a, w) <- listen m
  return $! fmap (\r -> (r, w)) a

liftPass :: Monad m => Pass w m (Maybe a) -> Pass w (MaybeT m) a
liftPass pass = mapMaybeT $ \m -> pass $ do
  a <- m
  return $! case a of
    Nothing -> (Nothing, id)
    Just (v, f) -> (Just v, f)

-- transformers' (the transformed monad contravariant)
instance Contravariant m => Contravariant (MaybeT m) where
  contramap f = MaybeT . contramap (fmap f) . runMaybeT

-- transformers' Foldable and Traversable
instance Foldable f => Foldable (MaybeT f) where
  foldMap f (MaybeT a) = foldMap (foldMap f) a
instance Traversable f => Traversable (MaybeT f) where
  traverse f (MaybeT a) = fmap MaybeT (traverse (traverse f) a)

instance MonadFix m => MonadFix (MaybeT m) where
  mfix f = MaybeT (mfix (runMaybeT . f . maybe bomb id))
    where bomb = error "mfix (MaybeT): inner computation returned Nothing"

-- transformers': between MaybeT and ExceptT
maybeToExceptT :: Functor m => e -> MaybeT m a -> ExceptT e m a
maybeToExceptT e (MaybeT m) = ExceptT (fmap (maybe (Left e) Right) m)

exceptToMaybeT :: Functor m => ExceptT e m a -> MaybeT m a
exceptToMaybeT m = MaybeT (fmap (either (const Nothing) Just) (runExceptT m))
