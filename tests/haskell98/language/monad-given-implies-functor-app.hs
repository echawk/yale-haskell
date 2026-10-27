-- A given Monad (t m) at an application of type variables gives
-- Functor (t m) too (free's intercalateT, calling iterTM).
{-# LANGUAGE FlexibleContexts #-}
module Main where
import Control.Monad.Trans.Class
import Control.Monad.Trans.Reader

g :: (Functor f, Monad m) => f a -> m ()
g _ = return ()

h :: (MonadTrans t, Monad (t m), Monad m) => t m a -> t m ()
h x = g x >> g (Just ())

main = runReaderT (h (return 1)) () >>= print
