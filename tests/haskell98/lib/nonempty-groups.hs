module Main (main) where
import qualified Data.List.NonEmpty as N
import Data.List.NonEmpty (NonEmpty(..))
main :: IO ()
main = do
  print (N.groupBy1 (\a b -> even a == even b) (2 :| [4, 1, 3, 6]))
  print (N.groupAllWith1 (`mod` 3) (1 :| [2, 3, 4, 5, 6 :: Int]))
  print (N.inits1 (1 :| [2, 3 :: Int]), N.tails1 (1 :| [2, 3 :: Int]))
  print (N.length (N.permutations1 (1 :| [2, 3 :: Int])))
