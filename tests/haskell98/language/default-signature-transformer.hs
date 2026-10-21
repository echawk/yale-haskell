{-# LANGUAGE DefaultSignatures, TypeFamilies, MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, UndecidableInstances #-}
import Control.Monad.State
import Control.Monad.Reader
import Control.Monad.Trans.Class

class Monad m => MonadCount v m | m -> v where
  tick :: v -> m Int
  default tick :: (MonadCount v n, MonadTrans t, t n ~ m) => v -> m Int
  tick = lift . tick

instance Monad m => MonadCount Int (StateT Int m) where
  tick k = do { modify (+ k); get }

instance MonadCount v m => MonadCount v (ReaderT r m)

main :: IO ()
main = evalStateT (runReaderT (tick 3 >> tick (4 :: Int)) "env") (10 :: Int) >>= print
