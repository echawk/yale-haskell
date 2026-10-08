-- Operator sections, left and right, with backquoted functions;
-- (- e) is negation rather than a section; unary minus binds less
-- tightly than ^.
module Main where
import Dialogue (stdout, appendChan, done, abort)

showInts :: [Int] -> String
showInts = unwords . map show

showI :: Int -> String
showI = show

out :: String
out = unlines
  [ showInts (map (+1) [1,2,3])
  , showInts (map (2^) [0,1,2,3])
  , showInts (map (^2) [0,1,2,3])
  , showInts (map (`div` 2) [7,8,9])
  , showInts (map (10 `div`) [1,2,3])
  , showInts (map (subtract 1) [1,2,3])
  , showInts (filter (/= 2) [1,2,3])
  , filter (`elem` "aeiou") "education"
  , showI ((- 1) + 5)
  , showI (- 2 ^ 2)
  , showI (10 - (- 3))
  , (("con" ++) . (++ "ion")) "cat"
  ]

main = appendChan stdout out abort done
