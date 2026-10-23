{-# LANGUAGE ConstraintKinds, FlexibleContexts #-}
module CsynCycleB where
import Control.Monad.State (MonadState)
type MonadCI m = (Monad m, MonadState Int m)
