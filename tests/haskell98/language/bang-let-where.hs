-- BangPatterns: let !x = e and a where's !x = e evaluate e (they were
-- bound lazily).
{-# LANGUAGE BangPatterns #-}
import Control.Exception
main = do
  r <- try (evaluate (let !x = (undefined :: Int) in 5 :: Int))
  putStrLn (either (\e -> const "strict" (e :: SomeException)) show r)
  r2 <- try (evaluate (f 3))
  putStrLn (either (\e -> const "strict" (e :: SomeException)) show r2)
 where f :: Int -> Int
       f n = n where !y = (undefined :: Int)
