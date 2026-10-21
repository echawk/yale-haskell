-- Control.Monad.Trans.Accum (transformers): an accumulation monad, which
-- can add to a monoidal value and look at what has been added so far.
module Control.Monad.Trans.Accum (
    AccumT(AccumT), Accum, accum, runAccum, execAccum, evalAccum, mapAccum,
    runAccumT, execAccumT, evalAccumT, mapAccumT, look, looks, add,
    liftCallCC, readerToAccumT, writerToAccumT
  ) where

import Control.Monad.Fix (MonadFix(mfix))
import PreludeModern
import Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Data.Functor.Identity
import Control.Monad.Trans.Reader (ReaderT(ReaderT, runReaderT))
import Control.Monad.Trans.Writer (WriterT(WriterT, runWriterT))

newtype AccumT w m a = AccumT (w -> m (a, w))

type Accum w = AccumT w Identity

accum :: Monad m => (w -> (a, w)) -> AccumT w m a
accum f = AccumT (\w -> return (f w))

runAccumT :: AccumT w m a -> w -> m (a, w)
runAccumT (AccumT f) = f

execAccumT :: Monad m => AccumT w m a -> w -> m w
execAccumT m w = runAccumT m w >>= \(_, w') -> return w'

evalAccumT :: (Monad m, Monoid w) => AccumT w m a -> w -> m a
evalAccumT m w = runAccumT m w >>= \(a, _) -> return a

mapAccumT :: (m (a, w) -> n (b, w)) -> AccumT w m a -> AccumT w n b
mapAccumT f m = AccumT (f . runAccumT m)

runAccum :: Accum w a -> w -> (a, w)
runAccum m = runIdentity . runAccumT m

execAccum :: Accum w a -> w -> w
execAccum m w = snd (runAccum m w)

evalAccum :: Monoid w => Accum w a -> w -> a
evalAccum m w = fst (runAccum m w)

mapAccum :: ((a, w) -> (b, w)) -> Accum w a -> Accum w b
mapAccum f = mapAccumT (Identity . f . runIdentity)

-- the added output, given what was there before
look :: (Monoid w, Monad m) => AccumT w m w
look = AccumT (\w -> return (w, mempty))

looks :: (Monoid w, Monad m) => (w -> a) -> AccumT w m a
looks f = AccumT (\w -> return (f w, mempty))

add :: Monad m => w -> AccumT w m ()
add w = AccumT (\_ -> return ((), w))

instance Functor m => Functor (AccumT w m) where
  fmap f m = AccumT (\w -> fmap (\(a, w') -> (f a, w')) (runAccumT m w))

instance (Monoid w, Monad m) => Applicative (AccumT w m) where
  pure a = AccumT (\_ -> return (a, mempty))
  mf <*> mx = mf >>= \f -> mx >>= \x -> return (f x)

instance (Monoid w, Monad m) => Monad (AccumT w m) where
  return = pure
  m >>= k = AccumT (\w -> runAccumT m w >>= \(a, w') ->
                          runAccumT (k a) (w `mappend` w') >>= \(b, w'') ->
                          return (b, w' `mappend` w''))

instance (Monoid w, MonadPlus m) => Alternative (AccumT w m) where
  empty = AccumT (const mzero)
  m <|> n = AccumT (\w -> runAccumT m w `mplus` runAccumT n w)

instance (Monoid w, MonadPlus m) => MonadPlus (AccumT w m) where
  mzero = empty
  mplus = (<|>)

instance (Monoid w, MonadFail m) => MonadFail (AccumT w m) where
  fail msg = AccumT (const (fail msg))

instance Monoid w => MonadTrans (AccumT w) where
  lift m = AccumT (\_ -> m >>= \a -> return (a, mempty))

instance (Monoid w, MonadIO m) => MonadIO (AccumT w m) where
  liftIO = lift . liftIO

liftCallCC :: ((((a, w) -> m (b, w)) -> m (a, w)) -> m (a, w))
           -> ((a -> AccumT w m b) -> AccumT w m a) -> AccumT w m a
liftCallCC callCC f = AccumT (\w ->
  callCC (\c -> runAccumT (f (\a -> AccumT (\_ -> c (a, w)))) w))

readerToAccumT :: (Functor m, Monoid w) => ReaderT w m a -> AccumT w m a
readerToAccumT (ReaderT f) = AccumT (\w -> fmap (\a -> (a, mempty)) (f w))

writerToAccumT :: WriterT w m a -> AccumT w m a
writerToAccumT (WriterT m) = AccumT (const m)

instance (Monoid w, MonadFix m) => MonadFix (AccumT w m) where
  mfix m = AccumT (\w -> mfix (\ ~(a, _) -> runAccumT (m a) w))
