-- Control.Monad.Trans.RWS.CPS (transformers): reader, writer and state,
-- the writer's output kept as part of the state (Writer.CPS's style).
module Control.Monad.Trans.RWS.CPS (
    RWS, rws, runRWS, evalRWS, execRWS,
    RWST, rwsT, runRWST, evalRWST, execRWST, mapRWST, withRWST,
    reader, ask, local, asks, writer, tell, listen, listens, pass, censor,
    state, get, put, modify, gets
  ) where

import Control.Monad.Fix (MonadFix(mfix))
import PreludeModern
import Control.Applicative (Alternative(empty, (<|>)))
import Control.Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class (MonadTrans(lift))
import Control.Monad.IO.Class (MonadIO(liftIO))
import Data.Functor.Identity (Identity(Identity), runIdentity)

newtype RWST r w s m a = RWST { unRWST :: r -> s -> w -> m (a, s, w) }

type RWS r w s = RWST r w s Identity

rwsT :: (Functor m, Monoid w) => (r -> s -> m (a, s, w)) -> RWST r w s m a
rwsT f = RWST (\r s w -> fmap (\(a, s', w') -> let wt = w `mappend` w' in wt `seq` (a, s', wt)) (f r s))

runRWST :: Monoid w => RWST r w s m a -> r -> s -> m (a, s, w)
runRWST m r s = unRWST m r s mempty

evalRWST :: (Monad m, Monoid w) => RWST r w s m a -> r -> s -> m (a, w)
evalRWST m r s = do { (a, _, w) <- runRWST m r s; return (a, w) }

execRWST :: (Monad m, Monoid w) => RWST r w s m a -> r -> s -> m (s, w)
execRWST m r s = do { (_, s', w) <- runRWST m r s; return (s', w) }

mapRWST :: (Monad n, Monoid w, Monoid w') => (m (a, s, w) -> n (b, s, w')) -> RWST r w s m a -> RWST r w' s n b
mapRWST f m = RWST (\r s w -> do
  (b, s', w') <- f (runRWST m r s)
  let wt = w `mappend` w'
  wt `seq` return (b, s', wt))

withRWST :: (r' -> s -> (r, s)) -> RWST r w s m a -> RWST r' w s m a
withRWST f m = RWST (\r s -> uncurry (unRWST m) (f r s))

rws :: Monoid w => (r -> s -> (a, s, w)) -> RWS r w s a
rws f = RWST (\r s w -> let (a, s', w') = f r s; wt = w `mappend` w' in wt `seq` return (a, s', wt))

runRWS :: Monoid w => RWS r w s a -> r -> s -> (a, s, w)
runRWS m r s = runIdentity (runRWST m r s)

evalRWS :: Monoid w => RWS r w s a -> r -> s -> (a, w)
evalRWS m r s = let (a, _, w) = runRWS m r s in (a, w)

execRWS :: Monoid w => RWS r w s a -> r -> s -> (s, w)
execRWS m r s = let (_, s', w) = runRWS m r s in (s', w)

instance Functor m => Functor (RWST r w s m) where
  fmap f m = RWST (\r s w -> fmap (\(a, s', w') -> (f a, s', w')) (unRWST m r s w))

instance (Functor m, Monad m) => Applicative (RWST r w s m) where
  pure a = RWST (\_ s w -> return (a, s, w))
  mf <*> mx = RWST (\r s w -> do
    (f, s', w') <- unRWST mf r s w
    (x, s'', w'') <- unRWST mx r s' w'
    return (f x, s'', w''))

instance (Functor m, MonadPlus m) => Alternative (RWST r w s m) where
  empty = RWST (\_ _ _ -> mzero)
  m <|> n = RWST (\r s w -> unRWST m r s w `mplus` unRWST n r s w)

instance Monad m => Monad (RWST r w s m) where
  return = pure
  m >>= k = RWST (\r s w -> do
    (a, s', w') <- unRWST m r s w
    unRWST (k a) r s' w')

instance MonadFail m => MonadFail (RWST r w s m) where
  fail msg = RWST (\_ _ _ -> fail msg)

instance (Functor m, MonadPlus m) => MonadPlus (RWST r w s m) where
  mzero = empty
  mplus = (<|>)

instance MonadTrans (RWST r w s) where
  lift m = RWST (\_ s w -> do { a <- m; return (a, s, w) })

instance MonadIO m => MonadIO (RWST r w s m) where
  liftIO = lift . liftIO

reader :: Monad m => (r -> a) -> RWST r w s m a
reader = asks

ask :: Monad m => RWST r w s m r
ask = asks id

local :: (r -> r) -> RWST r w s m a -> RWST r w s m a
local f m = RWST (\r s w -> unRWST m (f r) s w)

asks :: Monad m => (r -> a) -> RWST r w s m a
asks f = RWST (\r s w -> return (f r, s, w))

writer :: (Monoid w, Monad m) => (a, w) -> RWST r w s m a
writer (a, w') = RWST (\_ s w -> let wt = w `mappend` w' in wt `seq` return (a, s, wt))

tell :: (Monoid w, Monad m) => w -> RWST r w s m ()
tell w = writer ((), w)

listen :: (Monoid w, Monad m) => RWST r w s m a -> RWST r w s m (a, w)
listen = listens id

listens :: (Monoid w, Monad m) => (w -> b) -> RWST r w s m a -> RWST r w s m (a, b)
listens f m = RWST (\r s w -> do
  (a, s', w') <- runRWST m r s
  let wt = w `mappend` w'
  wt `seq` return ((a, f w'), s', wt))

pass :: (Monoid w, Monoid w', Monad m) => RWST r w s m (a, w -> w') -> RWST r w' s m a
pass m = RWST (\r s w -> do
  ((a, f), s', w') <- runRWST m r s
  let wt = w `mappend` f w'
  wt `seq` return (a, s', wt))

censor :: (Monoid w, Monad m) => (w -> w) -> RWST r w s m a -> RWST r w s m a
censor f m = RWST (\r s w -> do
  (a, s', w') <- runRWST m r s
  let wt = w `mappend` f w'
  wt `seq` return (a, s', wt))

state :: Monad m => (s -> (a, s)) -> RWST r w s m a
state f = RWST (\_ s w -> let (a, s') = f s in return (a, s', w))

get :: Monad m => RWST r w s m s
get = gets id

put :: Monad m => s -> RWST r w s m ()
put s = RWST (\_ _ w -> return ((), s, w))

modify :: Monad m => (s -> s) -> RWST r w s m ()
modify f = RWST (\_ s w -> return ((), f s, w))

gets :: Monad m => (s -> a) -> RWST r w s m a
gets f = RWST (\_ s w -> return (f s, s, w))

instance MonadFix m => MonadFix (RWST r w s m) where
  mfix f = RWST (\r s w -> mfix (\ ~(a, _, _) -> unRWST (f a) r s w))
