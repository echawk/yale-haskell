module Main (main) where
import GHC.Generics
import Data.Semigroup (Max(..))
main :: IO ()
main = do
  print (to (from (Just 'x')) :: Maybe Char, to1 (from1 (Max 3)) :: Max Int)
  print (to (from (1 :: Int, "a")) :: (Int, String), to1 (fmap succ (from1 [1, 2, 3 :: Int])) :: [Int])
