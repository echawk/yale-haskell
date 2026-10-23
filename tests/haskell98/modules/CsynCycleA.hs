{-# LANGUAGE ConstraintKinds, FlexibleContexts #-}
module CsynCycleA where
import {-# SOURCE #-} CsynCycleB (MonadCI)
import CsynCycleB
import Control.Monad.State (MonadState(get, put))
-- (CsynCycleB names MonadConv without importing MonadState)
type MonadConv m = (Monad m, MonadState Int m)
g :: MonadConv m => Int -> m Int
g n = do
  k <- get
  put (k + 1)
  return (n * 2 + k)
