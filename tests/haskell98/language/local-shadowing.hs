-- Local bindings, lambda arguments and patterns may shadow Prelude
-- names.
module Main where
import Dialogue (stdout, appendChan, done, abort)

count :: [a] -> Int
count map = length map

apply :: Int
apply = let id x = x + 1
            length = 7
        in id length

out :: String
out = unlines [ show (count "four")
              , show apply
              , show ((\filter -> filter * 2) (21 :: Int))
              , show (sum' [1, 2, 3]) ]
  where sum' xs = foldr (+) 0 (xs :: [Int]) where foldr = foldl

main = appendChan stdout out abort done
