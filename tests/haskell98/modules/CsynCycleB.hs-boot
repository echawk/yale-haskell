{-# LANGUAGE ConstraintKinds #-}
module CsynCycleB where
type MonadCI m = (Monad m, Functor m)
