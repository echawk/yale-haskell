-- length runs in constant stack (PreludeList: a foldr passing the count
-- along); a foldr summing 1s took a frame per element.
main :: IO ()
main = do
  print (length (filter even [1 .. 20000000 :: Int]))
  let xs = [1 .. 3000000] :: [Int]
  print (length xs, length (xs ++ xs), length ([] :: [Int]))
