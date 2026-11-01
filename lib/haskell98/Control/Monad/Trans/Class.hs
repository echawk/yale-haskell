{-# LANGUAGE QuantifiedConstraints, RankNTypes #-}
-- Control.Monad.Trans.Class (transformers): with transformers 0.6's
-- superclass, so that MonadTrans t and Monad m give Monad (t m)
module Control.Monad.Trans.Class (MonadTrans(lift)) where

-- (a quantified constraint's class is PreludeModern's)
import PreludeModern ()

class (forall m. Monad m => Monad (t m)) => MonadTrans t where
  lift :: Monad m => m a -> t m a
