-- Control.Monad.Cont.Class (mtl): MonadCont, with instances for the
-- transformers' monads.
module Control.Monad.Cont.Class (MonadCont(callCC)) where

import PreludeModern
import qualified Control.Monad.Trans.Cont as C
import Control.Monad.Trans.Cont (ContT)
import Control.Monad.Trans.Reader (ReaderT(ReaderT), runReaderT)
import qualified Control.Monad.Trans.State.Lazy as Lazy
import qualified Control.Monad.Trans.State.Strict as Strict
import Control.Monad.Trans.Except (ExceptT(ExceptT), runExceptT)
import Control.Monad.Trans.Maybe (MaybeT(MaybeT), runMaybeT)

class Monad m => MonadCont m where
  callCC :: ((a -> m b) -> m a) -> m a

instance MonadCont (ContT r m) where
  callCC = C.callCC

instance MonadCont m => MonadCont (ReaderT r m) where
  callCC f = ReaderT (\r -> callCC (\c -> runReaderT (f (\a -> ReaderT (\_ -> c a))) r))

instance MonadCont m => MonadCont (Lazy.StateT s m) where
  callCC f = Lazy.StateT (\s -> callCC (\c -> Lazy.runStateT (f (\a -> Lazy.StateT (\s' -> c (a, s')))) s))

instance MonadCont m => MonadCont (Strict.StateT s m) where
  callCC f = Strict.StateT (\s -> callCC (\c -> Strict.runStateT (f (\a -> Strict.StateT (\s' -> c (a, s')))) s))

instance MonadCont m => MonadCont (ExceptT e m) where
  callCC f = ExceptT (callCC (\c -> runExceptT (f (\a -> ExceptT (c (Right a))))))

instance MonadCont m => MonadCont (MaybeT m) where
  callCC f = MaybeT (callCC (\c -> runMaybeT (f (\a -> MaybeT (c (Just a))))))
