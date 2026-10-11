-- Specialization of overloaded functions at their callers' dictionaries
-- (doc/plans/SPECIALIZE.md): recursion, several types, a dictionary
-- built by an instance with a context, polymorphic recursion (a new
-- dictionary at each call: the budget stops it), a library function,
-- and a recursive let whose dependency a dictionary call used to hide.
import qualified Data.Map as M
import Numeric (fromRat)

mySum :: Num a => [a] -> a -> a
mySum [] acc = acc
mySum (x:xs) acc = mySum xs (acc + x)

member :: Ord a => a -> [a] -> Bool
member _ [] = False
member y (x:xs) = case compare y x of { EQ -> True; _ -> member y xs }

nest :: Show a => Int -> a -> String
nest 0 x = show x
nest n x = nest (n - 1) [x]

count :: Ord k => [k] -> M.Map k Int
count = foldr (\k m -> M.insertWith (+) k 1 m) M.empty

main :: IO ()
main = do
  print (mySum [1 .. 100000 :: Int] 0, mySum [0.5, 1.5 :: Double] 0)
  print (member (3 :: Int) [1, 2, 3], member 'z' "abc", member [1, 2 :: Int] [[1], [1, 2]])
  putStrLn (nest 3 'x')
  print (nest 70 True == concat (replicate 70 "[") ++ "True" ++ concat (replicate 70 "]"))
  print (M.toList (count "mississippi"), M.toList (count [3, 1, 3 :: Int]))
  print (fromRat (7 / 2) :: Double, fromRat (1 / 3) :: Float)
