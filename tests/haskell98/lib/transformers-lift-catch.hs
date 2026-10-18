-- transformers' liftCatch for StateT, ReaderT, MaybeT, RWST, IdentityT
import qualified Control.Monad.Trans.State.Lazy as L
import qualified Control.Monad.Trans.State.Strict as S
import Control.Monad.Trans.Reader
import Control.Monad.Trans.Maybe
import Control.Monad.Trans.Except
import Control.Monad.Trans.Writer
import Control.Monad.Trans.Class
import Control.Exception
import Control.Monad.Trans.RWS (RWST, runRWST)
import qualified Control.Monad.Trans.RWS as R
import Control.Monad.Trans.Identity

handler :: ArithException -> IO a
handler _ = ioError (userError "x")

main :: IO ()
main = do
  r <- L.runStateT (L.liftCatch catch (lift (evaluate (1 `div` 0)) >>= L.put) (\e -> lift (print (e :: ArithException)) >> L.put 7)) 0
  print r
  r2 <- S.runStateT (S.liftCatch catch (S.put 5 >> lift (throwIO DivideByZero)) (\e -> lift (print (e :: ArithException)))) 0
  print r2
  r3 <- runReaderT (Control.Monad.Trans.Reader.liftCatch catch (lift (throwIO Overflow)) (\e -> asks (\n -> show (e :: ArithException) ++ show n))) (3 :: Int)
  putStrLn r3
  r4 <- runMaybeT (Control.Monad.Trans.Maybe.liftCatch catch (lift (throwIO Overflow) >> return 'a') (\e -> const (return 'b') (e :: ArithException)))
  print r4
  r5 <- runRWST (R.liftCatch catch (R.tell "x" >> lift (throwIO Overflow)) (\e -> R.tell (show (e :: ArithException)))) () (0 :: Int)
  print r5
  r6 <- runIdentityT (Control.Monad.Trans.Identity.liftCatch catch (lift (throwIO Overflow)) (\e -> return (show (e :: ArithException))))
  putStrLn r6
