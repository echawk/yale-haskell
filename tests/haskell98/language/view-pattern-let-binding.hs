-- View patterns in a pattern binding (JHC's TempDir: let (normalise ->
-- dpart, _) = splitFileName fp): their variables are the binding's.
{-# LANGUAGE ViewPatterns #-}
module Main where

main = do
  let (map succ -> a, b) = ("abc", 1 :: Int)
  print (a, b)
  let g = let ((* 2) -> c, _) = (5 :: Int, 'x') in c
  print g

other = let (map succ -> z) = "abc" in z
