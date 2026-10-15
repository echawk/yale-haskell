-- ArithException: the host's division by zero and thrown constructors.
import Control.Exception
main = do
  r1 <- try (evaluate (1 `div` (0 :: Int))) :: IO (Either ArithException Int)
  r2 <- try (throwIO Overflow) :: IO (Either ArithException ())
  r3 <- try (throwIO RatioZeroDenominator) :: IO (Either SomeException ())
  r4 <- try (try (evaluate (error "boom" :: Int)) :: IO (Either ArithException Int))
  print (r1, r2, either show show r3)
  putStrLn (either (\e -> "ErrorCall: " ++ show (e :: ErrorCall)) show r4)
