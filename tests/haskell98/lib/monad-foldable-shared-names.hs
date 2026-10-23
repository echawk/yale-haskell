module Main where
import Control.Monad
import Data.Foldable
import Data.Traversable
main :: IO ()
main = do
  forM_ [1, 2 :: Int] print
  print (msum [Nothing, Just (3 :: Int), Just 4])
  xs <- forM [1, 2, 3 :: Int] (return . succ)
  print xs
