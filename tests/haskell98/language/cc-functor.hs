-- The Prelude's Functor class: fmap on lists and an instance for a
-- user-defined tree.
module Main where

data Tree a = Leaf a | Branch (Tree a) (Tree a)

instance Functor Tree where
  fmap f (Leaf x)     = Leaf (f x)
  fmap f (Branch l r) = Branch (fmap f l) (fmap f r)

fringe :: Tree a -> [a]
fringe (Leaf x)     = [x]
fringe (Branch l r) = fringe l ++ fringe r

tree :: Tree Int
tree = Branch (Leaf 1) (Branch (Leaf 2) (Leaf 3))

out :: String
out = unlines [ unwords (map show (fmap (* 10) [1, 2, 3 :: Int]))
              , unwords (fringe (fmap show tree))
              , show (sum (fringe (fmap (+ 1) tree))) ]

main = appendChan stdout out abort done
