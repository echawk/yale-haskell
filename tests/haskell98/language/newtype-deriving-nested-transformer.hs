{-# LANGUAGE GeneralizedNewtypeDeriving #-}
import Control.Monad.State
import Control.Monad.Reader

newtype T m a = T (ReaderT Int (StateT Int m) a)
  deriving (Functor, Applicative, Monad, MonadState Int, MonadReader Int)

run :: Monad m => T m a -> m (a, Int)
run (T x) = runStateT (runReaderT x 10) 1

main :: IO ()
main = run (do { n <- ask; modify (+ n); fmap (* 2) get }) >>= print
