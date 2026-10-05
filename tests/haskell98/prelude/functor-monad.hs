-- Functor and Monad for Maybe and lists, and the Prelude's monadic
-- utilities (pure code; no IO).
module Main where

half :: Int -> Maybe Int
half n = if even n then Just (n `div` 2) else Nothing

main = appendChan stdout (unlines [
  show (fmap (+ 1) (Just 3), fmap show [1, 2 :: Int]),
  show (Just 8 >>= half >>= half, Just 6 >>= half >>= half),
  show (sequence [Just 1, Just 2 :: Maybe Int], mapM half [2, 4, 6]),
  show ([1, 2] >>= \x -> [x, x * 10 :: Int], return 'x' :: [Char]),
  show (half =<< Just 10)
  ]) abort done
