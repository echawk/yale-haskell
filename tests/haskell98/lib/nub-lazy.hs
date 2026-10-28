import Data.List

main :: IO ()
main = do
  print (take 5 (nub (cycle [1, 2, 3, 4, 5, 6 :: Int])))
  print (take 3 (nub (1 : 2 : 3 : undefined :: [Int])))
  print (nub [3, 1, 3, 2, 1, 4 :: Int])
  print (nubBy (\a b -> a `mod` 3 == b `mod` 3) [1 .. 10 :: Int])
  print (nubBy (<) [3, 1, 4, 1, 5, 9, 2, 6 :: Int])
  print (nub "mississippi", nub ([] :: [Int]))
  print (length (nub (map (`mod` 500) [1 .. 5000 :: Int])))
