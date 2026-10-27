-- A multi-parameter class's default lifting through a transformer
-- (free's MonadFree f m, default wrap with m ~ t n): the class's
-- superclass Monad holds at t n for the default's join.
{-# LANGUAGE DefaultSignatures, FunctionalDependencies, TypeFamilies, FlexibleInstances, UndecidableInstances #-}
module Main where
import Control.Monad (join)
import Control.Monad.Trans.Class
import Control.Monad.Trans.Reader

class Monad m => MonadFree f m | m -> f where
  wrap :: f (m a) -> m a
  default wrap :: (m ~ t n, MonadTrans t, MonadFree f n, Functor f) => f (m a) -> m a
  wrap = join . lift . wrap . fmap return

newtype F a = F [a]
instance Functor F where fmap f (F xs) = F (map f xs)
instance MonadFree F [] where wrap (F xss) = concat xss
instance MonadFree F (ReaderT e []) 

main = print (runReaderT (wrap (F [return 1, return 2])) () :: [Int])
