-- Haskell 98's Monad library plus the Control.Monad names nofib's
-- harness code uses that came after Haskell 98 (forM, forM_,
-- replicateM, replicateM_, foldM_).  The conformance runner maps
-- Control.Monad to this module.
module NofibMonad (module Monad, forM, forM_, replicateM, replicateM_, foldM_) where

import Monad

forM :: Monad m => [a] -> (a -> m b) -> m [b]
forM = flip mapM

forM_ :: Monad m => [a] -> (a -> m b) -> m ()
forM_ = flip mapM_

replicateM :: Monad m => Int -> m a -> m [a]
replicateM n x = sequence (replicate n x)

replicateM_ :: Monad m => Int -> m a -> m ()
replicateM_ n x = sequence_ (replicate n x)

foldM_ :: Monad m => (a -> b -> m a) -> a -> [b] -> m ()
foldM_ f a xs = foldM f a xs >> return ()
