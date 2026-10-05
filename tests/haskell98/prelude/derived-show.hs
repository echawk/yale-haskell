-- Derived Show and Read: nullary constructors are not parenthesised,
-- infix constructors use their fixity.
module Main where

infixr 5 :::

data Tree a = Leaf | Node (Tree a) a (Tree a) deriving (Show, Read, Eq)

data L = Nil | Int ::: L deriving (Show, Read)

main = appendChan stdout (unlines [
  show (Node Leaf (1 :: Int) (Node Leaf 2 Leaf)),
  show (Just Leaf :: Maybe (Tree Int)),
  show (1 ::: 2 ::: Nil),
  show ((read "Node Leaf 3 Leaf" :: Tree Int) == Node Leaf 3 Leaf)
  ]) abort done
