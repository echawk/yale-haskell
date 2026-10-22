-- A signature followed by a right-hand side, x :: t | g = e (GHC: a
-- pattern binding with the signature)
module Main (main) where

describe :: Int -> String
describe n = word
  where
    word :: String
      | n < 0 = "negative"
      | otherwise = "non-negative"

two :: Int = 2

main :: IO ()
main = putStrLn (describe (-3)) >> putStrLn (describe 4) >> print two
