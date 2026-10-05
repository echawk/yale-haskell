-- Derived Eq and Ord: constructor order, lexicographic comparison of
-- fields, recursive and parameterised types.
module Main where

data Color = Red | Green | Blue deriving (Eq, Ord)

data Tree a = Leaf | Node (Tree a) a (Tree a) deriving (Eq, Ord)

data P = P Int Char deriving (Eq, Ord)

colorName :: Color -> String
colorName Red   = "Red"
colorName Green = "Green"
colorName Blue  = "Blue"

isort :: (Ord a) => [a] -> [a]
isort = foldr ins []
  where ins x []                 = [x]
        ins x (y:ys) | x <= y    = x : y : ys
                     | otherwise = y : ins x ys

t1, t2 :: Tree Int
t1 = Node Leaf 1 Leaf
t2 = Node Leaf 2 Leaf

out :: String
out = unlines
  [ show (Red < Blue, Green > Blue, Red == Red, Red /= Green)
  , colorName (max Green Red) ++ " " ++ colorName (minimum [Blue, Green])
  , unwords (map colorName (isort [Blue, Red, Green, Red]))
  , show (Leaf < t1, t1 < t2, Node t1 0 Leaf > Node Leaf 5 Leaf, t1 == Node Leaf 1 Leaf)
  , show (P 1 'b' < P 2 'a', P 1 'b' < P 1 'a', P 3 'x' == P 3 'x')
  , show ([Red, Blue] < [Red, Green], (Green, 1) < (Green, 2))
  ]

main = appendChan stdout out abort done
