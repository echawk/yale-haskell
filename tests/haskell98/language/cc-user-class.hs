-- A user-defined constructor class: the class variable f is applied to
-- types in the method signatures, with instances for [] and a user type.
module Main where
import Dialogue (stdout, appendChan, done, abort)

class Container f where
  empty  :: f a
  insert :: a -> f a -> f a
  toL    :: f a -> [a]
  cmap   :: (a -> b) -> f a -> f b

data Tree a = Leaf | Node (Tree a) a (Tree a)

instance Container [] where
  empty  = []
  insert = (:)
  toL    = id
  cmap   = map

instance Container Tree where
  empty = Leaf
  insert x Leaf         = Node Leaf x Leaf
  insert x (Node l y r) = Node (insert x l) y r
  toL Leaf         = []
  toL (Node l x r) = toL l ++ [x] ++ toL r
  cmap _ Leaf         = Leaf
  cmap f (Node l x r) = Node (cmap f l) (f x) (cmap f r)

fill :: (Container f) => [a] -> f a
fill = foldr insert empty

out :: String
out = unlines [ unwords (map show (toL (cmap (* 2) (fill [1, 2, 3] :: [Int]))))
              , unwords (map show (toL (cmap (+ 1) (fill [1, 2, 3] :: Tree Int)))) ]

main = appendChan stdout out abort done
