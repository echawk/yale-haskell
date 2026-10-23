{-# LANGUAGE ConstraintKinds #-}
module CsynCycleB where
import CsynCycleA
type MonadCI m = MonadConv m
class CI a where
  checkI' :: (MonadCI m) => a -> m a
instance CI Int where
  checkI' n = g n
