-- Parameterised algebraic data types: a binary tree with map and fold,
-- an option type, a sum of two types, constructors used as functions
-- and partially applied.
module Main where

data Tree a  = Leaf | Node (Tree a) a (Tree a)
data Opt a   = None | Some a
data Or a b  = L a | R b

insert :: (Ord a) => a -> Tree a -> Tree a
insert x Leaf = Node Leaf x Leaf
insert x t@(Node l y r) | x < y     = Node (insert x l) y r
                        | x > y     = Node l y (insert x r)
                        | otherwise = t

mapTree :: (a -> b) -> Tree a -> Tree b
mapTree _ Leaf         = Leaf
mapTree f (Node l x r) = Node (mapTree f l) (f x) (mapTree f r)

foldTree :: (b -> a -> b -> b) -> b -> Tree a -> b
foldTree _ z Leaf         = z
foldTree f z (Node l x r) = f (foldTree f z l) x (foldTree f z r)

toList :: Tree a -> [a]
toList = foldTree (\l x r -> l ++ [x] ++ r) []

safeDiv :: Int -> Int -> Opt Int
safeDiv _ 0 = None
safeDiv a b = Some (a `div` b)

showOpt :: Opt Int -> String
showOpt None     = "none"
showOpt (Some n) = "some " ++ show n

either' :: (a -> c) -> (b -> c) -> Or a b -> c
either' f _ (L a) = f a
either' _ g (R b) = g b

out :: String
out = unlines
  [ unwords (map show (toList (foldr insert Leaf [5, 2, 8, 1, 9, 2 :: Int])))
  , unwords (map show (toList (mapTree (* 10) (foldr insert Leaf [3, 1, 2 :: Int]))))
  , show (foldTree (\l _ r -> 1 + max l r) 0 (foldr insert Leaf [1..7 :: Int]))
  , unwords (map showOpt [safeDiv 7 2, safeDiv 1 0])
  , unwords (map (either' show id) [L (1 :: Int), R "two", L 3])
  , show (length (map (Node Leaf 'x') [Leaf, Leaf]))
  ]

main = appendChan stdout out abort done
