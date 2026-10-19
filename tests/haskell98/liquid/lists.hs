-- Lists and measures (--liquid; doc/plans/LIQUID-HASKELL.md, milestone 4):
-- len, a measure of the module's own, facts from pattern matching, and
-- the Prelude's list functions' specifications (head, !!, length, ++, ..).
module Main where

{-@ myMap :: (a -> b) -> xs:[a] -> {v:[b] | len v = len xs} @-}
myMap :: (a -> b) -> [a] -> [b]
myMap f [] = []
myMap f (x:xs) = f x : myMap f xs

safeHead :: [Int] -> Int
safeHead xs = if null xs then 0 else head xs

firsts :: [Int] -> Int
firsts xs = case xs of
              [] -> 0
              (y:ys) -> head xs + length ys

get :: [Int] -> Int -> Int
get xs i = if 0 <= i && i < length xs then xs !! i else 0

{-@ measure size :: [a] -> Int
      size []     = 0
      size (x:xs) = 1 + size xs
  @-}

{-@ dup :: xs:[a] -> {v:[a] | size v = 2 * size xs} @-}
dup :: [a] -> [a]
dup [] = []
dup (x:xs) = x : x : dup xs

main = print (myMap (+1) [1,2,3], safeHead [], firsts [4,5], get [1,2] 1,
              length (replicate 3 'a' ++ take 2 "xyz"), dup "ab")
