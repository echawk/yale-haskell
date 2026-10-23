{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Main where
import Control.Monad.Trans.Class (MonadTrans(lift))
import Control.Monad.Trans.Except (ExceptT, runExceptT)
newtype BlockT m a = BlockT { unBlockT :: ExceptT String m a }
  deriving (Functor, Applicative, Monad, MonadTrans)
main = runExceptT (unBlockT (lift (return 3) >>= \x -> return (x + 1 :: Int))) >>= print
