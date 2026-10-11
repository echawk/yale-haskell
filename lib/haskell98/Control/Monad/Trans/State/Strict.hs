-- Control.Monad.Trans.State.Strict (transformers)
module Control.Monad.Trans.State.Strict (
    StateT(StateT, runStateT), State, runState, evalState, execState,
    mapState, withState, evalStateT, execStateT, mapStateT, withStateT,
    state, get, put, modify, modify', gets
  ) where

import PreludeModern
import Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Data.Functor.Identity

newtype StateT s m a = StateT { runStateT :: s -> m (a, s) }

type State s = StateT s Identity

runState :: State s a -> s -> (a, s)
runState m s = runIdentity (runStateT m s)

evalState :: State s a -> s -> a
evalState m s = fst (runState m s)

execState :: State s a -> s -> s
execState m s = snd (runState m s)

mapState :: ((a, s) -> (b, s)) -> State s a -> State s b
mapState f m = StateT (\s -> Identity (f (runState m s)))

withState :: (s -> s) -> State s a -> State s a
withState = withStateT

evalStateT :: Monad m => StateT s m a -> s -> m a
evalStateT m s = runStateT m s >>= \(a, s') -> return a

execStateT :: Monad m => StateT s m a -> s -> m s
execStateT m s = runStateT m s >>= \(a, s') -> return s'

mapStateT :: (m (a, s) -> n (b, s)) -> StateT s m a -> StateT s n b
mapStateT f m = StateT (\s -> f (runStateT m s))

withStateT :: (s -> s) -> StateT s m a -> StateT s m a
withStateT f m = StateT (\s -> runStateT m (f s))

instance Monad m => Functor (StateT s m) where
  fmap f m = StateT (\s -> runStateT m s >>= \(a, s') -> return (f a, s'))
  {-# fmap :: Inline #-}

instance Monad m => Applicative (StateT s m) where
  pure a = StateT (\s -> return (a, s))
  mf <*> mx = StateT (\s -> runStateT mf s >>= \(f, s') ->
                             runStateT mx s' >>= \(x, s'') -> return (f x, s''))
  {-# pure :: Inline #-}
  {-# (<*>) :: Inline #-}

instance Monad m => Monad (StateT s m) where
  return a = StateT (\s -> return (a, s))
  m >>= k = StateT (\s -> runStateT m s >>= \(a, s') -> runStateT (k a) s')
  m >> k = m >>= \_ -> k
  {-# return :: Inline #-}
  {-# (>>=) :: Inline #-}
  {-# (>>) :: Inline #-}

instance MonadPlus m => Alternative (StateT s m) where
  empty = StateT (\_ -> mzero)
  m <|> n = StateT (\s -> runStateT m s `mplus` runStateT n s)

instance MonadPlus m => MonadPlus (StateT s m) where
  mzero = StateT (\_ -> mzero)
  m `mplus` n = StateT (\s -> runStateT m s `mplus` runStateT n s)

instance MonadFail m => MonadFail (StateT s m) where
  fail msg = StateT (\_ -> fail msg)

instance MonadTrans (StateT s) where
  lift m = StateT (\s -> m >>= \a -> return (a, s))

instance MonadIO m => MonadIO (StateT s m) where
  liftIO io = lift (liftIO io)

state :: Monad m => (s -> (a, s)) -> StateT s m a
state f = StateT (\s -> return (f s))

get :: Monad m => StateT s m s
get = state (\s -> (s, s))

put :: Monad m => s -> StateT s m ()
put s = state (\_ -> ((), s))

modify :: Monad m => (s -> s) -> StateT s m ()
modify f = state (\s -> ((), f s))

modify' :: Monad m => (s -> s) -> StateT s m ()
modify' f = StateT (\s -> let s' = f s in s' `seq` return ((), s'))

gets :: Monad m => (s -> a) -> StateT s m a
gets f = state (\s -> (f s, s))

{-# runState :: Inline #-}
{-# evalState :: Inline #-}
{-# execState :: Inline #-}
{-# state :: Inline #-}
{-# get :: Inline #-}
{-# put :: Inline #-}
{-# modify :: Inline #-}
{-# modify' :: Inline #-}
{-# gets :: Inline #-}
