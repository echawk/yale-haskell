-- `let' qualifiers in list comprehensions (H98 report 3.11).
module Main where
import Dialogue (stdout, appendChan, done, abort)

doubledOdd :: [Int] -> [Int]
doubledOdd xs = [ y | x <- xs, let y = x * 2, odd x ]

-- let first, several bindings, a local function, and later generators
-- that use the bindings.
table :: [String]
table = [ show a ++ "*" ++ show b ++ "=" ++ show c
        | let n = 3
              sq k = k * k
        , a <- [1 .. n]
        , let b = sq a
        , b > 1
        , let c = a * b ]

-- let as the last qualifier, and an explicit-brace let.
pairs :: [(Int, Int)]
pairs = [ p | x <- [1, 2], let { y = x + 10; p = (x, y) } ]

-- A polymorphic let binding used at two types.
poly :: [(Int, Bool)]
poly = [ (ident n, ident (n > 1)) | n <- [1, 2], let ident z = z ]

-- `let ... in' is still an ordinary boolean filter.
filtered :: [Int]
filtered = [ x | x <- [1 .. 10], let h = x `div` 2 in h * 2 == x ]

-- Only lets: a singleton list.
single :: [Int]
single = [ a + b | let a = 1, let b = 2 ]

-- Nested comprehensions with lets.
nested :: [[Int]]
nested = [ [ z | y <- [1 .. x], let z = x * y ] | x <- [1 .. 3], let w = x, w /= 2 ]

showPair :: (Int, Int) -> String
showPair (a, b) = show a ++ "," ++ show b

showPB :: (Int, Bool) -> String
showPB (a, b) = show a ++ ":" ++ show b

result :: String
result = unlines
  [ unwords (map show (doubledOdd [1 .. 7]))
  , unwords table
  , unwords (map showPair pairs)
  , unwords (map showPB poly)
  , unwords (map show filtered)
  , unwords (map show single)
  , unwords (map (unwords . map show) nested)
  ]

main = appendChan stdout result abort done
