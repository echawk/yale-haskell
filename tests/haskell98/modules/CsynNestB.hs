{-# LANGUAGE ConstraintKinds, FlexibleContexts, FlexibleInstances #-}
module CsynNestB where
import CsynNestA
import Control.Monad.State (State, modify)

class (MonadPretty m) => Warn m where
  warn :: String -> m ()
  warnTwice :: Warn m => String -> m ()
  warnTwice s = warn s >> warn s

instance Warn (State Int) where
  warn _ = modify (+ 1)
