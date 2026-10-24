{-# LANGUAGE TemplateHaskell, QuasiQuotes #-}
module Main where
import PatGen

swap :: (Int, Int) -> (Int, Int)
swap $(pairP "x" "y") = (y, x)

isOneTwoThree :: [Integer] -> Bool
isOneTwoThree [nums|1 2 3|] = True
isOneTwoThree _ = False

main :: IO ()
main = do
  print (swap (1, 2))
  print (isOneTwoThree [nums|1 2 3|], isOneTwoThree [3, 2, 1])
  print (case (5, 6) of $(pairP "a" "b") -> a * b)
