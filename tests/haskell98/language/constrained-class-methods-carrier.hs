-- ConstrainedClassMethods on a one-parameter class: a method's own
-- constraint on the class's variable (recursion-schemes' gpara ::
-- Corecursive t => .. in class Recursive t).  At an instance its
-- dictionary is the method's parameter at the instance's type (Show [a]),
-- not reduced (Show a), as callers pass it.
module Main where

class Sized t where
  size :: t -> Int
  describe :: Show t => t -> String
  describe x = show x ++ " of size " ++ show (size x)
  bigger :: Ord t => t -> t -> t
  bigger a b = if size a >= size b then a else b

instance Sized [a] where
  size = length

newtype Box = Box Int deriving Show
instance Sized Box where
  size (Box n) = n
  describe (Box n) = "box " ++ show n

main = do
  putStrLn (describe [1,2,3::Int])
  print (bigger "ab" "xyz")
  putStrLn (describe (Box 4))
