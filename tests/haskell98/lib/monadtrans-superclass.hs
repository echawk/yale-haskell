import Control.Monad.Trans.Class
import Control.Monad.Trans.State.Strict
import Control.Monad.Trans.Reader
import Control.Monad.Trans.Maybe

-- Monad (t m) from MonadTrans t and Monad m (transformers >= 0.6)
liftBoth :: (MonadTrans t, Monad m) => m a -> m b -> t m (a, b)
liftBoth ma mb = do { a <- lift ma; b <- lift mb; return (a, b) }

main :: IO ()
main = do
  print =<< evalStateT (liftBoth (return 1) (return 'x')) ()
  print =<< runReaderT (liftBoth (return "r") (return True)) ()
  print =<< runMaybeT (liftBoth (return 2) (return 3))
