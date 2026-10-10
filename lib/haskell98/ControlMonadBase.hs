-- ControlMonadBase: the definitions Control.Monad adds to Haskell 98's
-- Monad, shared by Control.Monad (the 2010 Report's, lib/haskell98/
-- Control/Monad.hs) and base's (lib/haskell98/modern/Control/Monad.hs,
-- for --modern-prelude).  Not a library module for programs.
module ControlMonadBase (
    Functor(fmap), Monad((>>=), (>>), return, fail), MonadPlus(mzero, mplus),
    mapM, mapM_, forM, forM_, sequence, sequence_, (=<<), (>=>), (<=<),
    forever, void, join, msum, filterM, mapAndUnzipM, zipWithM, zipWithM_,
    foldM, foldM_, replicateM, replicateM_, guard, when, unless,
    liftM, liftM2, liftM3, liftM4, liftM5, ap
  ) where

import Monad

infixr 1 >=>, <=<

forM :: Monad m => [a] -> (a -> m b) -> m [b]
forM = flip mapM

forM_ :: Monad m => [a] -> (a -> m b) -> m ()
forM_ = flip mapM_

(>=>) :: Monad m => (a -> m b) -> (b -> m c) -> (a -> m c)
f >=> g = \x -> f x >>= g

(<=<) :: Monad m => (b -> m c) -> (a -> m b) -> (a -> m c)
(<=<) = flip (>=>)

forever :: Monad m => m a -> m b
forever a = a >> forever a

void :: Functor f => f a -> f ()
void = fmap (const ())

foldM_ :: Monad m => (a -> b -> m a) -> a -> [b] -> m ()
foldM_ f a xs = foldM f a xs >> return ()

replicateM :: Monad m => Int -> m a -> m [a]
replicateM n x = sequence (replicate n x)

replicateM_ :: Monad m => Int -> m a -> m ()
replicateM_ n x = sequence_ (replicate n x)
