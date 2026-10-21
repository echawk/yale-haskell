module Main (main) where
import Data.Array.IArray (Array, listArray, (!), Ix(range, rangeSize))
main :: IO ()
main = print (range (1 :: Int, 3), rangeSize (0 :: Int, 4), (listArray (0, 2) "abc" :: Array Int Char) ! 1)
