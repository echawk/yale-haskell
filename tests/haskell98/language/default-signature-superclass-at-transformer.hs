{-# LANGUAGE DefaultSignatures, TypeFamilies, FlexibleContexts #-}
module Main where
import Control.Monad.Trans.Class (MonadTrans(lift))
import Control.Monad.Trans.Reader (ReaderT, runReaderT)
twice :: (MonadTrans t, Monad (t m), Monad m) => m Int -> t m Int
twice x = do { a <- lift x; b <- lift x; return (a + b) }
class Monad m => RT m where
  getS :: m Int
  default getS :: (MonadTrans t, RT n, t n ~ m) => m Int
  getS = twice getS
instance RT IO where getS = return 20
instance RT m => RT (ReaderT r m)
main = runReaderT getS () >>= print
