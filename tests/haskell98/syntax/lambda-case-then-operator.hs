{-# LANGUAGE LambdaCase #-}
module Main where

orElse :: Maybe a -> (() -> Maybe a) -> Maybe a
orElse (Just x) _ = Just x
orElse Nothing k = k ()

andThen :: Maybe a -> (a -> Maybe b) -> Maybe b
andThen m k = m >>= k

f :: Int -> Maybe Int
f n = Just n
  `orElse` \case
    () -> do
      Just 0
  `andThen` \x -> do
    Just (x + 1)

class C a where
  conv
    :: (Show b)
    => b -> a -> String
  default conv
    :: (Show a, Show b)
    => b -> a -> String
  conv b a = show b ++ show a

instance C Int

main :: IO ()
main = print (f 3, conv 'x' (4 :: Int))
