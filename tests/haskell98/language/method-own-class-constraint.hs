{-# LANGUAGE ConstraintKinds, FlexibleContexts, FlexibleInstances #-}
module Main where
import Control.Monad.State (MonadState(get), State, modify, runState)
type MonadInner m = (Monad m, MonadState Int m)
type MonadPretty m = MonadInner m
pretty :: MonadPretty m => m String
pretty = fmap show get

class (MonadPretty m) => Warn m where
  warn :: String -> m ()
  warnTwice :: Warn m => String -> m ()
  warnTwice s = warn s >> warn s

instance Warn (State Int) where
  warn _ = modify (+ 1)

main :: IO ()
main = print (runState (warnTwice "x" >> pretty) 0)
