-- Control.Monad.IO.Class (base)
module Control.Monad.IO.Class (MonadIO(liftIO)) where

class Monad m => MonadIO m where
  liftIO :: IO a -> m a

instance MonadIO IO where
  liftIO io = io
