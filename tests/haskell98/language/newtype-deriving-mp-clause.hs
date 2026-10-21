{-# LANGUAGE GeneralizedNewtypeDeriving, FlexibleContexts #-}
import Control.Monad.State
import Control.Monad.Reader

newtype App a = App (ReaderT Int (State String) a)
  deriving (Functor, Applicative, Monad, MonadState String, MonadReader Int)

newtype AppT m a = AppT { unAppT :: StateT Int m a }
  deriving (Functor, Applicative, Monad, MonadState Int)

runApp :: App a -> (a, String)
runApp (App m) = runState (runReaderT m 5) "s"

step :: App Int
step = do { n <- ask; modify (++ show n); s <- get; return (length s + n) }

stepT :: (MonadState Int m) => m Int
stepT = do { modify (* 3); get }

main :: IO ()
main = do
  print (runApp step)
  r <- runStateT (unAppT (stepT >> stepT)) 2
  print r
