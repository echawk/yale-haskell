{-# LANGUAGE RankNTypes #-}
-- Control.Monad.ST.Lazy (base): a type of its own, as in GHC, but strict
-- underneath (Control.Monad.ST's monad, wrapped): actions run when
-- sequenced, not when their results are demanded.
module Control.Monad.ST.Lazy (
    ST, runST, fixST, strictToLazyST, lazyToStrictST, RealWorld, stToIO
  ) where

import PreludeModern
import qualified Control.Monad.ST as S
import Control.Monad.ST (RealWorld)
import Control.Monad.Fix (MonadFix(mfix))

newtype ST s a = ST (S.ST s a)

unLazy :: ST s a -> S.ST s a
unLazy (ST m) = m

instance Functor (ST s) where
  fmap f (ST m) = ST (fmap f m)

instance Applicative (ST s) where
  pure = ST . pure
  ST f <*> ST a = ST (f <*> a)

instance Monad (ST s) where
  return = pure
  ST m >>= k = ST (m >>= \a -> unLazy (k a))

instance MonadFix (ST s) where
  mfix = fixST

runST :: (forall s. ST s a) -> a
runST m = S.runST (unLazy m)

fixST :: (a -> ST s a) -> ST s a
fixST k = ST (S.fixST (\a -> unLazy (k a)))

strictToLazyST :: S.ST s a -> ST s a
strictToLazyST = ST

lazyToStrictST :: ST s a -> S.ST s a
lazyToStrictST = unLazy

stToIO :: ST RealWorld a -> IO a
stToIO = S.stToIO . unLazy
