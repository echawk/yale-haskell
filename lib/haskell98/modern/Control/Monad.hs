-- Control.Monad as in GHC's base, for --modern-prelude (modules under
-- lib/haskell98/modern/ are found before the library's own,
-- csys/compiler-driver.mumble): as the 2010 Report's, but guard is
-- Alternative's (base's), and base's additions.
module Control.Monad (
    Functor(fmap), Monad((>>=), (>>), return, fail), MonadPlus(mzero, mplus),
    mapM, mapM_, forM, forM_, sequence, sequence_, (=<<), (>=>), (<=<),
    forever, void, join, msum, filterM, mapAndUnzipM, zipWithM, zipWithM_,
    foldM, foldM_, replicateM, replicateM_, guard, when, unless, mfilter, (<$!>),
    liftM, liftM2, liftM3, liftM4, liftM5, ap
  ) where

import ControlMonadBase hiding (guard)
import PreludeModern (Applicative(pure), Alternative(empty))

infixl 4 <$!>

guard :: Alternative f => Bool -> f ()
guard True  = pure ()
guard False = empty

mfilter :: MonadPlus m => (a -> Bool) -> m a -> m a
mfilter p ma = do { a <- ma; if p a then return a else mzero }

(<$!>) :: Monad m => (a -> b) -> m a -> m b
f <$!> m = do { x <- m; let { z = f x }; z `seq` return z }
