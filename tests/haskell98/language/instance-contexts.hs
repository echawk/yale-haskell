-- Hand-written instances with contexts for parameterised types, and
-- instances for lists, tuples, unit and function types.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data Tree a = Leaf | Node (Tree a) a (Tree a)

instance (Eq a) => Eq (Tree a) where
  Leaf         == Leaf         = True
  Node l x r   == Node l' y r' = x == y && l == l' && r == r'
  _            == _            = False

class Size a where
  size :: a -> Int

instance Size Int where
  size _ = 1

instance Size Bool where
  size _ = 1

instance Size () where
  size _ = 0

instance (Size a) => Size [a] where
  size xs = sum (map size xs)

instance (Size a, Size b) => Size (a, b) where
  size (a, b) = size a + size b

instance Size (a -> b) where
  size _ = 99

out :: String
out = unlines
  [ show (Node Leaf 'a' Leaf == Node Leaf 'a' Leaf, Node Leaf 1 Leaf == Leaf)
  , show (size [(1 :: Int, True), (2, False)])
  , show (size ([] :: [Int]), size (), size [[True], [False, True]])
  , show (size not)
  ]

main = appendChan stdout out abort done
