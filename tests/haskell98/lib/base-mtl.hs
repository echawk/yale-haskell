-- mtl: MonadState, MonadReader, MonadWriter, MonadError over the transformers.
import Control.Monad.State
import Control.Monad.Reader
import Control.Monad.Writer
import Control.Monad.Except
import Control.Monad (when)

counter :: (MonadState Int m) => m Int
counter = do { modify (+ 1); n <- get; when (n > 2) (put 100); gets (* 2) }

app :: ReaderT Int (StateT Int IO) String
app = do
  r <- ask
  modify (+ r)
  s <- get
  liftIO (putStrLn ("in app: " ++ show s))
  local (* 10) (asks show)

logged :: (MonadWriter [String] m, MonadState Int m) => m ()
logged = do { x <- get; tell ["saw " ++ show x]; put (x + 1) }

safeDiv :: MonadError String m => Int -> Int -> m Int
safeDiv _ 0 = throwError "divide by zero"
safeDiv a b = return (a `div` b)

main :: IO ()
main = do
  print (runState counter 0, runState (counter >> counter >> counter) 0)
  (res, st) <- runStateT (runReaderT app 5) 1
  print (res, st)
  print (runState (runWriterT (logged >> logged)) 7)
  print (runExcept (safeDiv 10 2), runExcept (safeDiv 1 0 `catchError` (\e -> return (length e))))
  print (safeDiv 7 0 :: Either String Int)
