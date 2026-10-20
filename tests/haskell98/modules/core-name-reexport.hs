module Main (main) where
import qualified CoreClashB as R
main :: IO ()
main = do
  case R.enumFromTo 1 2 of R.Stream xs -> print xs
  print [1 .. 3 :: Int]
