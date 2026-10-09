-- Control.Monad: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module Monad
-- and the Prelude names the 2010 Report lists, plus what 2010 added.
module Control.Monad (
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
