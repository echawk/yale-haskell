{-# LANGUAGE DefaultSignatures, TypeFamilies, FlexibleContexts #-}
module Main where
import Control.Monad.Trans.Class (MonadTrans(lift))
import Control.Monad.Trans.Reader (ReaderT, runReaderT)
import Control.Monad.Trans.Maybe (MaybeT, runMaybeT)
class Monad m => RT m where
  getS :: m Int
  default getS :: (MonadTrans t, RT n, t n ~ m) => m Int
  getS = lift getS
instance RT IO where getS = return 41
instance RT m => RT (ReaderT r m)
instance RT m => RT (MaybeT m)
main = do
  n <- runReaderT getS ()
  Just k <- runMaybeT (runReaderT getS 'c')
  print (n + 1, k)
