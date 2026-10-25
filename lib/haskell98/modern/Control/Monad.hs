-- Control.Monad as in GHC's base, for --modern-prelude (modules under
-- lib/haskell98/modern/ are found before the library's own,
-- csys/compiler-driver.mumble): as the 2010 Report's, but guard is
-- Alternative's (base's), replicateM, when, forever, filterM, zipWithM
-- and their _ forms are over Applicative (base's), mapM, forM, sequence, msum and their _ forms are
-- over Traversable or Foldable (base's), and base's additions.  MonadFail
-- is exported without its fail, which a module gets from the Prelude:
-- library modules (mtl's) re-export Control.Monad under the core Prelude.
module Control.Monad (
    Functor(fmap), Monad((>>=), (>>), return, fail), MonadFail,
    MonadPlus(mzero, mplus),
    mapM, mapM_, forM, forM_, sequence, sequence_, (=<<), (>=>), (<=<),
    forever, void, join, msum, filterM, mapAndUnzipM, zipWithM, zipWithM_,
    foldM, foldM_, replicateM, replicateM_, guard, when, unless, mfilter, (<$!>),
    liftM, liftM2, liftM3, liftM4, liftM5, ap
  ) where

import Prelude hiding (mapM, mapM_, sequence, sequence_, foldr)
import Data.Traversable (forM)
import Data.Foldable (forM_, msum)
import ControlMonadBase hiding (guard, mapM, mapM_, forM, forM_, sequence,
                               sequence_, msum, replicateM, replicateM_, when,
                               unless, forever, filterM, zipWithM, zipWithM_,
                               foldM, foldM_)
import PreludeModern (Applicative(pure, (<*>), (*>)), liftA2, Alternative(empty), MonadFail,
                      Traversable(mapM, sequence), Foldable(foldr),
                      mapM_, sequence_)

-- over a Foldable, as base's (emojis' foldM over t Int)
foldM :: (Foldable t, Monad m) => (b -> a -> m b) -> b -> t a -> m b
foldM f z0 xs = foldr c return xs z0
  where c x k z = f z x >>= k

foldM_ :: (Foldable t, Monad m) => (b -> a -> m b) -> b -> t a -> m ()
foldM_ f z xs = foldM f z xs >> return ()

-- over an Applicative, as base's since 4.9
replicateM :: Applicative m => Int -> m a -> m [a]
replicateM n m = loop n
  where loop k | k <= 0 = pure []
               | otherwise = liftA2 (:) m (loop (k - 1))

replicateM_ :: Applicative m => Int -> m a -> m ()
replicateM_ n m = loop n
  where loop k | k <= 0 = pure ()
               | otherwise = m *> loop (k - 1)

when, unless :: Applicative f => Bool -> f () -> f ()
when p s = if p then s else pure ()
unless p s = if p then pure () else s
{-# when :: Inline #-}
{-# unless :: Inline #-}

forever :: Applicative f => f a -> f b
forever a = let a' = a *> a' in a'

filterM :: Applicative m => (a -> m Bool) -> [a] -> m [a]
filterM p = foldr (\x -> liftA2 (\flg -> if flg then (x :) else id) (p x)) (pure [])

zipWithM :: Applicative m => (a -> b -> m c) -> [a] -> [b] -> m [c]
zipWithM f xs ys = sequenceA' (zipWith f xs ys)
  where sequenceA' = foldr (liftA2 (:)) (pure [])

zipWithM_ :: Applicative m => (a -> b -> m c) -> [a] -> [b] -> m ()
zipWithM_ f xs ys = foldr (*>) (pure ()) (zipWith f xs ys)

-- over any Traversable or Foldable, as base's (forM is Data.Traversable's,
-- the one entity in both, as in base)

-- (forM_ and msum are Data.Foldable's)

infixl 4 <$!>

guard :: Alternative f => Bool -> f ()
guard True  = pure ()
guard False = empty

mfilter :: MonadPlus m => (a -> Bool) -> m a -> m a
mfilter p ma = do { a <- ma; if p a then return a else mzero }

(<$!>) :: Monad m => (a -> b) -> m a -> m b
f <$!> m = do { x <- m; let { z = f x }; z `seq` return z }
