-- Derived Read parses what derived Show prints, with extra spaces and
-- parentheses allowed (Haskell 98 section 10.4).
module Main where

data Color = Red | Green | Blue deriving (Show, Read, Eq)
data Tree a = Leaf | Node (Tree a) a (Tree a) deriving (Show, Read)

out :: String
out = unlines [ show (read "Blue" :: Color)
              , show (read " ( Node Leaf 3 (Node Leaf (-4) Leaf) ) " :: Tree Int)
              , show (read "[Red,Green]" :: [Color])
              , show ((read "(Red, 7)" :: (Color, Int)) == (Red, 7))
              , show (map fst (reads "Green rest" :: [(Color, String)])) ]

main = appendChan stdout out abort done
