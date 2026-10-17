-- A program's own exception types (Typeable-based, as in base),
-- Handler and catches, catchJust, mask.
import Control.Exception
import Data.Typeable

data MyErr = MyErr String Int deriving Show
instance Exception MyErr

data Other = Other deriving Show
instance Exception Other

main = do
  r <- try (throwIO (MyErr "boom" 3)) :: IO (Either MyErr ())
  print r
  r2 <- try (evaluate (1 `div` (0 :: Int)))
  print (r2 :: Either ArithException Int)
  s <- (throw Other >> return "no") `catches`
         [ Handler (\(MyErr m _) -> return ("my " ++ m))
         , Handler (\e -> return ("other " ++ show (e :: Other))) ]
  putStrLn s
  (try (throwIO (MyErr "x" 1)) >>= \r -> print (r :: Either Other ()))
    `catch` \e -> putStrLn ("outer: " ++ show (e :: SomeException))
  x <- catchJust (\e -> if e == DivideByZero then Just () else Nothing)
                 (evaluate (5 `div` (0 :: Int))) (\_ -> return 0)
  print x
  mask $ \restore -> restore (putStrLn "masked") >> restore (return ())
  throwIO (MyErr "uncaught" 9)
