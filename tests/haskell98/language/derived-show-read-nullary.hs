-- Derived Show and Read: nullary constructors are not
-- parenthesised when shown, and are read back without parentheses.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data Tree a = Leaf | Node (Tree a) a (Tree a) deriving (Eq, Show, Read)

data Color = Red | Green deriving (Eq, Show, Read)

data Item = Item Color [Color] deriving (Eq, Show, Read)

main = appendChan stdout (unlines [
  show (Node Leaf (1 :: Int) (Node Leaf 2 Leaf)),
  show (Just Leaf :: Maybe (Tree Int)),
  show (Just (Item Red [Green, Red])),
  show ((read "Node Leaf 3 Leaf" :: Tree Int) == Node Leaf 3 Leaf),
  show ((read "Just Leaf" :: Maybe (Tree Int)) == Just Leaf),
  show (read " ( Green ) " == Green)
  ]) abort done
