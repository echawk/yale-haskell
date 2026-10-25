-- Control.Monad.State.Class (mtl): MonadState, with instances for the
-- transformers' monads.
module Control.Monad.State.Class (MonadState(get, put, state), modify, modify', gets) where

import PreludeModern
import Control.Monad.Trans.Class
import qualified Control.Monad.Trans.State.Lazy as Lazy
import qualified Control.Monad.Trans.State.Strict as Strict
import Control.Monad.Trans.Reader (ReaderT(ReaderT), runReaderT)
import Control.Monad.Trans.Writer.Lazy (WriterT)
import Control.Monad.Trans.Maybe (MaybeT)
import Control.Monad.Trans.Except (ExceptT)
import qualified Control.Monad.Trans.RWS.Lazy as RWSL
import qualified Control.Monad.Trans.RWS.Strict as RWSS
import qualified Control.Monad.Trans.Writer.Strict as WS

class Monad m => MonadState s m | m -> s where
  get   :: m s
  put   :: s -> m ()
  state :: (s -> (a, s)) -> m a
  -- mtl's defaults: get and put, or state
  get = state (\s -> (s, s))
  put s = state (\_ -> ((), s))
  state f = get >>= \s -> let ~(a, s') = f s in put s' >> return a

modify :: MonadState s m => (s -> s) -> m ()
modify f = state (\s -> ((), f s))

modify' :: MonadState s m => (s -> s) -> m ()
modify' f = get >>= \s -> let s' = f s in s' `seq` put s'

gets :: MonadState s m => (s -> a) -> m a
gets f = state (\s -> (f s, s))

instance Monad m => MonadState s (Lazy.StateT s m) where
  get = Lazy.get
  put = Lazy.put
  state = Lazy.state
  {-# get :: Inline #-}
  {-# put :: Inline #-}
  {-# state :: Inline #-}

instance Monad m => MonadState s (Strict.StateT s m) where
  get = Strict.get
  put = Strict.put
  state = Strict.state
  {-# get :: Inline #-}
  {-# put :: Inline #-}
  {-# state :: Inline #-}

instance (Monad m, MonadState s m) => MonadState s (ReaderT r m) where
  get = lift get
  put s = lift (put s)
  state f = lift (state f)

instance (Monoid w, Monad m, MonadState s m) => MonadState s (WriterT w m) where
  get = lift get
  put s = lift (put s)
  state f = lift (state f)

instance (Monad m, MonadState s m) => MonadState s (MaybeT m) where
  get = lift get
  put s = lift (put s)
  state f = lift (state f)

instance (Monad m, MonadState s m) => MonadState s (ExceptT e m) where
  get = lift get
  put s = lift (put s)
  state f = lift (state f)

{-# modify :: Inline #-}
{-# modify' :: Inline #-}
{-# gets :: Inline #-}

instance (Monoid w, Monad m) => MonadState s (RWSL.RWST r w s m) where
  get = RWSL.get
  put = RWSL.put
  state = RWSL.state

instance (Monoid w, Monad m) => MonadState s (RWSS.RWST r w s m) where
  get = RWSS.get
  put = RWSS.put
  state = RWSS.state

instance (Monoid w, Monad m, MonadState s m) => MonadState s (WS.WriterT w m) where
  get = lift get
  put s = lift (put s)
  state f = lift (state f)
