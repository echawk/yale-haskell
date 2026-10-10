-- transformers: StateT (lazy, strict), ReaderT, WriterT, MaybeT, ExceptT, Identity.
import Control.Monad.Trans.State
import qualified Control.Monad.Trans.State.Strict as S
import Control.Monad.Trans.Reader
import Control.Monad.Trans.Writer
import Control.Monad.Trans.Maybe
import Control.Monad.Trans.Except
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Data.Functor.Identity

counter :: State Int Int
counter = do { modify (+ 1); x <- get; put (x * 10); gets (+ 1) }

walk :: StateT Int IO ()
walk = do { n <- get; liftIO (print n); put (n + 1); m <- get; lift (print m) }

choose :: StateT Int [] Int
choose = do { x <- lift [1, 2, 3]; s <- get; put (s + x); return (x * s) }

main :: IO ()
main = do
  print (runState counter 4)
  print (S.evalState (mapM (\x -> S.modify' (+ x) >> S.get) [1 .. 5]) 0)
  execStateT walk 7 >>= print
  print (runStateT choose 10)
  print (runReader (do { x <- ask; y <- asks (* 2); local (+ 1) (asks (+ (x + y))) }) 5)
  print (runWriter (tell "a" >> tell "b" >> return (3 :: Int)))
  r <- runMaybeT (do { x <- MaybeT (return (Just 1)); y <- hoistMaybe Nothing; return (x + y :: Int) })
  print r
  print (runExcept (throwE "boom" `catchE` (\e -> return (length e))) :: Either String Int)
  print (runIdentity (Identity 4 >>= \x -> return (x + 1)))
