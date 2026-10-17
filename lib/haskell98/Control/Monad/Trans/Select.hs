-- Control.Monad.Trans.Select (transformers): the selection monad, which
-- picks a value given a way to rank the results.
module Control.Monad.Trans.Select (
    SelectT(SelectT), Select, select, runSelect, mapSelect, runSelectT,
    mapSelectT, selectToContT
  ) where

import PreludeModern
import Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Data.Functor.Identity
import Control.Monad.Trans.Cont (ContT(ContT))

newtype SelectT r m a = SelectT ((a -> m r) -> m a)

type Select r = SelectT r Identity

select :: ((a -> r) -> a) -> Select r a
select f = SelectT (\k -> Identity (f (runIdentity . k)))

runSelect :: Select r a -> (a -> r) -> a
runSelect m k = runIdentity (runSelectT m (Identity . k))

mapSelect :: (a -> a) -> Select r a -> Select r a
mapSelect f = mapSelectT (Identity . f . runIdentity)

runSelectT :: SelectT r m a -> (a -> m r) -> m a
runSelectT (SelectT g) = g

mapSelectT :: (m a -> m a) -> SelectT r m a -> SelectT r m a
mapSelectT f m = SelectT (f . runSelectT m)

instance Functor m => Functor (SelectT r m) where
  fmap f (SelectT g) = SelectT (\k -> fmap f (g (k . f)))

instance Monad m => Applicative (SelectT r m) where
  pure a = SelectT (\_ -> return a)
  mf <*> mx = mf >>= \f -> mx >>= \x -> return (f x)

instance Monad m => Monad (SelectT r m) where
  return = pure
  SelectT g >>= f = SelectT (\k ->
    let h x = runSelectT (f x) k
    in g (\x -> h x >>= k) >>= h)

instance MonadPlus m => Alternative (SelectT r m) where
  empty = SelectT (const mzero)
  SelectT f <|> SelectT g = SelectT (\k -> f k `mplus` g k)

instance MonadPlus m => MonadPlus (SelectT r m) where
  mzero = empty
  mplus = (<|>)

instance MonadFail m => MonadFail (SelectT r m) where
  fail msg = SelectT (\_ -> fail msg)

instance MonadTrans (SelectT r) where
  lift = SelectT . const

instance MonadIO m => MonadIO (SelectT r m) where
  liftIO = lift . liftIO

selectToContT :: Monad m => SelectT r m a -> ContT r m a
selectToContT (SelectT g) = ContT (\k -> g k >>= k)
