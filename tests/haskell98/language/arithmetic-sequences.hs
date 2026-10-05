-- Arithmetic sequences on Int, Char and Double: [a..], [a..b],
-- [a,b..c], descending and empty ranges.
module Main where

showInts :: [Int] -> String
showInts = unwords . map show

tenths :: [Double] -> [Int]
tenths = map (\x -> round (x * 10))

out :: String
out = unlines
  [ showInts [1..10]
  , showInts [1,3..11]
  , showInts [10,8..1]
  , showInts [5..1]
  , showInts (take 3 [7..])
  , showInts (take 4 [0,5..])
  , ['a'..'f']
  , ['a','c'..'k']
  , showInts (tenths [1.0,1.5..3.0])
  , showInts (tenths [0.1,0.2..0.5])
  ]

main = appendChan stdout out abort done
