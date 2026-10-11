-- Control.Monad as in GHC's base, for --modern-prelude (modules under
-- lib/haskell98/modern/ are found before the library's own,
-- csys/compiler-driver.mumble): as the 2010 Report's, but guard is
-- Alternative's (base's), mapM, forM, sequence, msum and their _ forms are
-- over Traversable or Foldable (base's), and base's additions.
module Control.Monad (
    Functor(fmap), Monad((>>=), (>>), return, fail), MonadPlus(mzero, mplus),
    mapM, mapM_, forM, forM_, sequence, sequence_, (=<<), (>=>), (<=<),
    forever, void, join, msum, filterM, mapAndUnzipM, zipWithM, zipWithM_,
    foldM, foldM_, replicateM, replicateM_, guard, when, unless, mfilter, (<$!>),
    liftM, liftM2, liftM3, liftM4, liftM5, ap
  ) where

import Prelude hiding (mapM, mapM_, sequence, sequence_, foldr)
import ControlMonadBase hiding (guard, mapM, mapM_, forM, forM_, sequence,
                               sequence_, msum)
import PreludeModern (Applicative(pure), Alternative(empty),
                      Traversable(mapM, sequence), Foldable(foldr),
                      mapM_, sequence_)

-- over any Traversable or Foldable, as base's
forM :: (Traversable t, Monad m) => t a -> (a -> m b) -> m (t b)
forM t f = mapM f t
{-# forM :: Inline #-}

forM_ :: (Foldable t, Monad m) => t a -> (a -> m b) -> m ()
forM_ t f = mapM_ f t
{-# forM_ :: Inline #-}

msum :: (Foldable t, MonadPlus m) => t (m a) -> m a
msum t = foldr mplus mzero t

infixl 4 <$!>

guard :: Alternative f => Bool -> f ()
guard True  = pure ()
guard False = empty

mfilter :: MonadPlus m => (a -> Bool) -> m a -> m a
mfilter p ma = do { a <- ma; if p a then return a else mzero }

(<$!>) :: Monad m => (a -> b) -> m a -> m b
f <$!> m = do { x <- m; let { z = f x }; z `seq` return z }
