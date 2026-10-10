-- A multi-parameter class with a functional dependency: f -> e improves
-- the element type when the container type is known.
module Main where

class Container f e | f -> e where
  empty  :: f
  insert :: e -> f -> f
  toL    :: f -> [e]

newtype IntBag = IntBag [Int]

instance Container IntBag Int where
  empty = IntBag []
  insert x (IntBag xs) = IntBag (x:xs)
  toL (IntBag xs) = xs

fill :: Container f e => [e] -> f
fill = foldr insert empty

total :: IntBag -> Int
total b = sum (toL b)

main :: IO ()
main = do
  let b = insert 3 (insert 4 empty) :: IntBag
  print (toL b)
  print (total (fill [1,2,3]))
