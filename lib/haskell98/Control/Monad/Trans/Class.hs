-- Control.Monad.Trans.Class (transformers)
module Control.Monad.Trans.Class (MonadTrans(lift)) where

class MonadTrans t where
  lift :: Monad m => m a -> t m a
