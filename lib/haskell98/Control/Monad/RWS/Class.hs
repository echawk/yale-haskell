{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, UndecidableInstances #-}
-- Control.Monad.RWS.Class (mtl): the monads with a reader, a writer and
-- a state.
module Control.Monad.RWS.Class (
    MonadRWS, module Control.Monad.Reader.Class,
    module Control.Monad.Writer.Class, module Control.Monad.State.Class
  ) where

import PreludeModern
import Control.Monad.Reader.Class
import Control.Monad.Writer.Class
import Control.Monad.State.Class
import qualified Control.Monad.Trans.RWS.Lazy as Lazy
import qualified Control.Monad.Trans.RWS.Strict as Strict
import Control.Monad.Trans.Except (ExceptT)
import Control.Monad.Trans.Maybe (MaybeT)

class (Monoid w, MonadReader r m, MonadWriter w m, MonadState s m)
   => MonadRWS r w s m | m -> r, m -> w, m -> s

instance (Monoid w, Monad m) => MonadRWS r w s (Lazy.RWST r w s m)
instance (Monoid w, Monad m) => MonadRWS r w s (Strict.RWST r w s m)
instance MonadRWS r w s m => MonadRWS r w s (ExceptT e m)
instance MonadRWS r w s m => MonadRWS r w s (MaybeT m)
