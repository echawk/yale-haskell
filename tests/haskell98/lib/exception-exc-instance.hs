-- The exception a match on SomeException gives is an Exception
-- (tasty-hunit's \(SomeException ex) -> displayException ex).
import Control.Exception
main = do
  r <- (Right <$> evaluate (1 `div` (0 :: Int))) `catch` \(SomeException ex) -> return (Left (displayException ex))
  print r
  r2 <- try (throwIO (userError "x")) :: IO (Either SomeException ())
  either (\(SomeException e) -> putStrLn (displayException e)) return r2
