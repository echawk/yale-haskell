{-# LANGUAGE ConstraintKinds #-}
module CsynCycleA where
import {-# SOURCE #-} CsynCycleB (MonadCI)
import CsynCycleB
type MonadConv m = (Monad m, Functor m)
g :: MonadConv m => Int -> m Int
g n = return (n * 2)
