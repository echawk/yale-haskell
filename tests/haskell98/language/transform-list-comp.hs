{-# LANGUAGE TransformListComp #-}
import GHC.Exts (sortWith, groupWith, the)
import Data.List (sortBy)
main = do
  print [ (the dept, sum salary) | (dept, salary) <- [("a", 1), ("b", 2), ("a", 3 :: Int)], then group by dept using groupWith ]
  print [ x | x <- [1 .. 10 :: Int], even x, then reverse, then take 2 ]
  print [ (x, y) | x <- [1, 2, 3 :: Int], y <- "ab", then sortWith by (negate x) ]
  print [ x | x <- [1, 2, 3 :: Int], then group using (\xs -> [xs, xs]) ]
