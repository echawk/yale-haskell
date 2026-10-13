-- Control.Monad.Trans.Cont (transformers): the continuation monad
-- transformer.
module Control.Monad.Trans.Cont (
    ContT(ContT, runContT), Cont, cont, runCont, evalContT, evalCont,
    mapContT, withContT, callCC, resetT, shiftT, reset, shift
  ) where

import PreludeModern
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Data.Functor.Identity

newtype ContT r m a = ContT { runContT :: (a -> m r) -> m r }

type Cont r = ContT r Identity

cont :: ((a -> r) -> r) -> Cont r a
cont f = ContT (\c -> Identity (f (runIdentity . c)))

runCont :: Cont r a -> (a -> r) -> r
runCont m k = runIdentity (runContT m (Identity . k))

evalContT :: Monad m => ContT r m r -> m r
evalContT m = runContT m return

evalCont :: Cont r r -> r
evalCont m = runIdentity (evalContT m)

mapContT :: (m r -> m r) -> ContT r m a -> ContT r m a
mapContT f m = ContT (f . runContT m)

withContT :: ((b -> m r) -> (a -> m r)) -> ContT r m a -> ContT r m b
withContT f m = ContT (runContT m . f)

callCC :: ((a -> ContT r m b) -> ContT r m a) -> ContT r m a
callCC f = ContT (\c -> runContT (f (\a -> ContT (\_ -> c a))) c)

resetT :: Monad m => ContT r m r -> ContT r' m r
resetT = lift . evalContT

shiftT :: Monad m => ((a -> m r) -> ContT r m r) -> ContT r m a
shiftT f = ContT (evalContT . f)

reset :: Cont r r -> Cont r' r
reset = resetT

shift :: ((a -> r) -> Cont r r) -> Cont r a
shift f = shiftT (f . (runIdentity .))

instance Functor (ContT r m) where
  fmap f m = ContT (\c -> runContT m (c . f))

instance Applicative (ContT r m) where
  pure x = ContT (\c -> c x)
  f <*> v = ContT (\c -> runContT f (\g -> runContT v (c . g)))

instance Monad (ContT r m) where
  return x = ContT (\c -> c x)
  m >>= k = ContT (\c -> runContT m (\x -> runContT (k x) c))

instance MonadTrans (ContT r) where
  lift m = ContT (m >>=)

instance MonadIO m => MonadIO (ContT r m) where
  liftIO = lift . liftIO
