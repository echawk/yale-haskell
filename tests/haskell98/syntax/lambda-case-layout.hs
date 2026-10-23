{-# LANGUAGE LambdaCase #-}
module Main where
f :: Either Int Char -> Maybe Int
f = \v -> case v of Left x -> Just x
                    _      -> Nothing
g :: Either Int Char -> Maybe Int
g = \case
  Left x -> Just x
  _      -> Nothing
h :: Either Int Char -> Maybe Int
h = \case Left x -> Just x
          Right _ -> Nothing
main :: IO ()
main = print (map f [Left 1, Right 'a'], map g [Left 1], map h [Left 2])
