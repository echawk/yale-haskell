-- Control.Monad.Trans.RWS.Lazy (transformers): a reader, writer and
-- state monad in one, its results matched lazily.
module Control.Monad.Trans.RWS.Lazy (
    RWST(RWST, runRWST), RWS, rws, runRWS, evalRWS, execRWS, evalRWST,
    execRWST, mapRWST, withRWST, reader, ask, local, asks, writer, tell,
    listen, listens, pass, censor, state, get, put, modify, gets
  ) where

import PreludeModern
import Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Data.Functor.Identity

newtype RWST r w s m a = RWST { runRWST :: r -> s -> m (a, s, w) }

type RWS r w s = RWST r w s Identity

rws :: Monoid w => (r -> s -> (a, s, w)) -> RWS r w s a
rws f = RWST (\r s -> Identity (f r s))

runRWS :: RWS r w s a -> r -> s -> (a, s, w)
runRWS m r s = runIdentity (runRWST m r s)

evalRWS :: RWS r w s a -> r -> s -> (a, w)
evalRWS m r s = let (a, _, w) = runRWS m r s in (a, w)

execRWS :: RWS r w s a -> r -> s -> (s, w)
execRWS m r s = let (_, s', w) = runRWS m r s in (s', w)

evalRWST :: Monad m => RWST r w s m a -> r -> s -> m (a, w)
evalRWST m r s = runRWST m r s >>= \ ~(a, _, w) -> return (a, w)

execRWST :: Monad m => RWST r w s m a -> r -> s -> m (s, w)
execRWST m r s = runRWST m r s >>= \ ~(_, s', w) -> return (s', w)

mapRWST :: (m (a, s, w) -> n (b, s, w')) -> RWST r w s m a -> RWST r w' s n b
mapRWST f m = RWST (\r s -> f (runRWST m r s))

withRWST :: (r' -> s -> (r, s)) -> RWST r w s m a -> RWST r' w s m a
withRWST f m = RWST (\r s -> uncurry (runRWST m) (f r s))

instance Functor m => Functor (RWST r w s m) where
  fmap f m = RWST (\r s -> fmap (\ ~(a, s', w) -> (f a, s', w)) (runRWST m r s))

instance (Monoid w, Monad m) => Applicative (RWST r w s m) where
  pure a = RWST (\_ s -> return (a, s, mempty))
  mf <*> mx = RWST (\r s -> runRWST mf r s >>= \ ~(f, s', w) ->
                     runRWST mx r s' >>= \ ~(x, s'', w') -> return (f x, s'', w `mappend` w'))

instance (Monoid w, Monad m) => Monad (RWST r w s m) where
  return = pure
  m >>= k = RWST (\r s -> runRWST m r s >>= \ ~(a, s', w) ->
                   runRWST (k a) r s' >>= \ ~(b, s'', w') -> return (b, s'', w `mappend` w'))

instance (Monoid w, MonadFail m) => MonadFail (RWST r w s m) where
  fail msg = RWST (\_ _ -> fail msg)

instance (Monoid w, MonadPlus m) => Alternative (RWST r w s m) where
  empty = RWST (\_ _ -> mzero)
  m <|> n = RWST (\r s -> runRWST m r s `mplus` runRWST n r s)

instance (Monoid w, MonadPlus m) => MonadPlus (RWST r w s m) where
  mzero = empty
  mplus = (<|>)

instance Monoid w => MonadTrans (RWST r w s) where
  lift m = RWST (\_ s -> m >>= \a -> return (a, s, mempty))

instance (Monoid w, MonadIO m) => MonadIO (RWST r w s m) where
  liftIO io = lift (liftIO io)

reader :: (Monoid w, Monad m) => (r -> a) -> RWST r w s m a
reader = asks

ask :: (Monoid w, Monad m) => RWST r w s m r
ask = RWST (\r s -> return (r, s, mempty))

local :: (r -> r) -> RWST r w s m a -> RWST r w s m a
local f m = RWST (\r s -> runRWST m (f r) s)

asks :: (Monoid w, Monad m) => (r -> a) -> RWST r w s m a
asks f = RWST (\r s -> return (f r, s, mempty))

writer :: Monad m => (a, w) -> RWST r w s m a
writer (a, w) = RWST (\_ s -> return (a, s, w))

tell :: Monad m => w -> RWST r w s m ()
tell w = RWST (\_ s -> return ((), s, w))

listen :: Monad m => RWST r w s m a -> RWST r w s m (a, w)
listen m = RWST (\r s -> runRWST m r s >>= \ ~(a, s', w) -> return ((a, w), s', w))

listens :: Monad m => (w -> b) -> RWST r w s m a -> RWST r w s m (a, b)
listens f m = RWST (\r s -> runRWST m r s >>= \ ~(a, s', w) -> return ((a, f w), s', w))

pass :: Monad m => RWST r w s m (a, w -> w) -> RWST r w s m a
pass m = RWST (\r s -> runRWST m r s >>= \ ~((a, f), s', w) -> return (a, s', f w))

censor :: Monad m => (w -> w) -> RWST r w s m a -> RWST r w s m a
censor f m = RWST (\r s -> runRWST m r s >>= \ ~(a, s', w) -> return (a, s', f w))

state :: (Monoid w, Monad m) => (s -> (a, s)) -> RWST r w s m a
state f = RWST (\_ s -> let (a, s') = f s in return (a, s', mempty))

get :: (Monoid w, Monad m) => RWST r w s m s
get = RWST (\_ s -> return (s, s, mempty))

put :: (Monoid w, Monad m) => s -> RWST r w s m ()
put s = RWST (\_ _ -> return ((), s, mempty))

modify :: (Monoid w, Monad m) => (s -> s) -> RWST r w s m ()
modify f = RWST (\_ s -> return ((), f s, mempty))

gets :: (Monoid w, Monad m) => (s -> a) -> RWST r w s m a
gets f = RWST (\_ s -> return (f s, s, mempty))
