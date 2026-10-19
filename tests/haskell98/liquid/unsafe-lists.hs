-- Lists and measures (--liquid, milestone 4), unsafe: a map that drops
-- elements (line 9), head of a possibly empty list (lines 12, 16), an
-- index that can reach the length (line 20).
module Main where

{-@ myMap :: (a -> b) -> xs:[a] -> {v:[b] | len v = len xs} @-}
myMap :: (a -> b) -> [a] -> [b]
myMap f [] = []
myMap f (x:xs) = myMap f xs

unsafeHead :: [Int] -> Int
unsafeHead xs = head xs

firsts :: [Int] -> Int
firsts xs = case xs of
              [] -> head xs
              (y:ys) -> head ys

get :: [Int] -> Int -> Int
get xs i = if 0 <= i && i <= length xs then xs !! i else 0

main = print (myMap (+1) [1,2,3], unsafeHead [1], firsts [4,5], get [1,2] 1)
