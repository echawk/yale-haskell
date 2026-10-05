-- The Ix library.
module Main where

import Ix

-- (Text is needed because Yale's Ix still has Text as a superclass.)
data Colour = Red | Green | Blue deriving (Eq, Ord, Ix, Text)

main = appendChan stdout (unlines [
  show (range (1, 4 :: Int), index (10, 20 :: Int) 15, inRange (1, 5 :: Integer) 7),
  show (range ('a', 'e'), index ('a', 'z') 'c', rangeSize ('a', 'z')),
  show (range ((0, 0), (1, 2 :: Int)), index ((0, 0), (1, 2 :: Int)) (1, 1)),
  show (rangeSize ((1, 2), (2, 1 :: Int)), rangeSize (5, 1 :: Int), rangeSize (1, 5 :: Integer)),
  show (range (False, True), index (LT, GT) GT, range ((), ())),
  show (map (index (Red, Blue)) [Red, Green, Blue], inRange (Green, Blue) Red, rangeSize (Red, Blue)),
  show (range ((0, 'a', False), (1, 'b', True)) !! 5)
  ]) abort done
