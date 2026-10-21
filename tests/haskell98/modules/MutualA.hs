module MutualA (Tree(..), size) where
import {-# SOURCE #-} MutualB (Forest, forestSize)

data Tree = Node Int Forest

size :: Tree -> Int
size (Node _ f) = 1 + forestSize f
