{-# LANGUAGE ConstraintKinds, FlexibleContexts #-}
module CsynNestA where
import {-# SOURCE #-} CsynNestB (Warn(..))
import Control.Monad.State (MonadState(get))
type MonadInner m = (Monad m, MonadState Int m)
type MonadPretty m = MonadInner m
pretty :: MonadPretty m => m String
pretty = fmap show get
