{-# LANGUAGE TemplateHaskell #-}
module Main where
import Test.QuickCheck
import Test.QuickCheck.All

prop_reverse :: [Int] -> Bool
prop_reverse xs = reverse (reverse xs) == xs

prop_append :: [Int] -> [Int] -> Bool
prop_append xs ys = length (xs ++ ys) == length xs + length ys

prop_plus_zero :: Int -> Bool
prop_plus_zero n = n == n + 0

return []
main :: IO ()
main = $(quickCheckAll) >>= print
