-- H98 report 2.3: `--' starts a comment only when the dashes are not
-- part of a larger operator symbol, and `-' and `~' may appear anywhere
-- in an operator.
module Main where

infixr 1 -->
infixl 6 |--, +-, ~~, <--

(-->) :: Bool -> Bool -> Bool
a --> b = not a || b

(|--) :: Int -> Int -> Int
a |-- b = a - 2 * b

(+-) :: Int -> Int -> Int
a +- b = a * 100 + b

(~~) :: Int -> Int -> Int
a ~~ b = a * b - 1

(<--) :: [Int] -> Int -> [Int]
xs <-- x = x : xs

data Clause = Int :- [Int]

render :: Clause -> String
render (h :- b) = show h ++ " :- " ++ unwords (map show b)

--- three dashes: still a comment
---------- and so is a rule of dashes
-- | a Haddock-style comment is a comment too

result :: String
result = unlines
  [ show (True --> False) ++ " " ++ show (False --> False)   -- comment after code
  , show (10 |-- 3)
  , show (1 +- 2)
  , show (3 ~~ 4)
  , unwords (map show ([1] <-- 2))
  , render (1 :- [2, 3])
  , show (5 - (-1))
  , show (negate 4 + 1)
  ]

main = appendChan stdout result abort done
