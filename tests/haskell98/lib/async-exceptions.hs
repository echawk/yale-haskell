-- Asynchronous exception classes (SomeAsyncException), the blocked
-- exceptions, TBQueue, and Hashable ThreadId (for the async package).
import Control.Exception
import Control.Concurrent
import Control.Concurrent.STM
import Data.Hashable

data Boom = Boom deriving Show
instance Exception Boom where
  toException = asyncExceptionToException
  fromException = asyncExceptionFromException

main :: IO ()
main = do
  r <- try (throwIO Boom)
  case r of { Left Boom -> putStrLn "caught Boom"; Right () -> return () }
  r2 <- try (throwIO Boom)
  case r2 of { Left (SomeAsyncException e) -> putStrLn ("async: " ++ show e); Right () -> return () }
  r3 <- try (throwIO BlockedIndefinitelyOnMVar)
  case r3 of { Left e -> print (e :: SomeException); Right () -> return () }
  q <- newTBQueueIO 2
  atomically (writeTBQueue q 1 >> writeTBQueue q (2 :: Int))
  f <- atomically (isFullTBQueue q)
  x <- atomically (readTBQueue q)
  n <- atomically (lengthTBQueue q)
  print (f, x, n)
  tid <- myThreadId
  print (hash tid == hash tid)
