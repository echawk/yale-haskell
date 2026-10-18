-- A multi-parameter instance whose types are not simple (FlexibleInstances):
-- indexed-traversable's FoldableWithIndex [Int] Tree.
{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FunctionalDependencies #-}
class Indexed i f | f -> i where indices :: f a -> [i]
data Tree a = Node a [Tree a]
instance Indexed [Int] Tree where
  indices (Node _ ts) = [] : concat (zipWith (\i t -> map (i :) (indices t)) [0 ..] ts)
main :: IO ()
main = print (indices (Node (0 :: Int) [Node 1 [], Node 2 [Node 3 []]]))
