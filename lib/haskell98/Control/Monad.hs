-- Control.Monad: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module Monad
-- and the Prelude names the 2010 Report lists, plus what 2010 added
-- (ControlMonadBase).  With --modern-prelude, lib/haskell98/modern/
-- Control/Monad.hs (base's) is used instead.
module Control.Monad (
    Functor(fmap), Monad((>>=), (>>), return, fail), MonadPlus(mzero, mplus),
    mapM, mapM_, forM, forM_, sequence, sequence_, (=<<), (>=>), (<=<),
    forever, void, join, msum, filterM, mapAndUnzipM, zipWithM, zipWithM_,
    foldM, foldM_, replicateM, replicateM_, guard, when, unless,
    liftM, liftM2, liftM3, liftM4, liftM5, ap
  ) where

import ControlMonadBase
