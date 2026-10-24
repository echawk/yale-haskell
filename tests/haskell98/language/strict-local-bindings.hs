-- Strict: local bindings are strict but those marked ~.
{-# LANGUAGE Strict #-}
import Control.Exception
probe :: a -> IO String
probe ~x = fmap (either (\e -> const "strict" (e :: SomeException)) (const "lazy")) (try (evaluate x))
f :: Int -> Int
f n = n + 1 where y = (undefined :: Int)
g :: Int -> Int
g n = let ~z = (undefined :: Int) in n
main = do
  probe (let x = (undefined :: Int) in 5 :: Int) >>= putStrLn
  probe (f 1) >>= putStrLn
  probe (g 1) >>= putStrLn
  do { let { !w = (undefined :: Int) }; return () } `catch` (\e -> putStrLn ("do-let " ++ const "strict" (e :: SomeException)))
