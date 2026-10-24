-- Strict: function and lambda arguments are strict but those marked ~.
{-# LANGUAGE Strict #-}
import Control.Exception
f :: Int -> Int -> Int
f x y = x
g :: Int -> Int -> Int
g x ~y = x
h :: Int -> Int
h = \x -> 7
probe :: a -> IO String
probe ~x = fmap (either (\e -> const "strict" (e :: SomeException)) (const "lazy")) (try (evaluate x))
main = do
  probe (f 1 undefined) >>= putStrLn
  probe (g 1 undefined) >>= putStrLn
  probe (h undefined) >>= putStrLn
