-- Lambda abstractions: several arguments, tuple and list patterns,
-- nesting and capture of enclosing variables.
module Main where
import Dialogue (stdout, appendChan, done, abort)

adders :: [Int -> Int]
adders = map (\n -> \x -> x + n) [1, 10, 100]

showInts :: [Int] -> String
showInts = unwords . map show

out :: String
out = unlines
  [ show ((\x y -> x * 10 + y) 4 2)
  , showInts (map (\(a, b) -> a - b) [(5, 1), (9, 3)])
  , show ((\(c:_) -> c) "lambda")
  , showInts (map (\f -> f 1) adders)
  , showInts (foldr (\x acc -> x : take 2 acc) [] [1..10])
  , show ((\f -> f (f 3)) (\z -> z * z))
  ]

main = appendChan stdout out abort done
