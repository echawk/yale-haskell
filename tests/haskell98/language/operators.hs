-- User-defined operators: top-level fixity declarations (infixl,
-- infixr, infix), operators defined infix on the left-hand side,
-- backquoted functions with and without a fixity, constructor
-- operators in expressions and patterns.
module Main where

infixr 5 +++
infixl 6 <^>
infix  4 ===
infixr 5 :>
infixl 6 `minus`

data Stream = Int :> Stream | End

(+++) :: [a] -> [a] -> [a]
xs +++ ys = foldr (:) ys xs

(<^>) :: Int -> Int -> Int
a <^> b = a - b

(===) :: Int -> Int -> Bool
a === b = a == b

minus :: Int -> Int -> Int
a `minus` b = a - b

plus :: Int -> Int -> Int
plus a b = a + b

toList :: Stream -> [Int]
toList (x :> s) = x : toList s
toList End      = []

out :: String
out = unlines
  [ "ab" +++ "cd" +++ "ef"
  , show (10 <^> 3 <^> 2)                    -- left associative: 5
  , show (1 + 2 === 3)                       -- === binds looser than +
  , show (10 `minus` 2 * 3)                  -- infixl 6: 10 - 6
  , show (1 `plus` 2 * 3)                    -- default infixl 9: (1+2)*3
  , unwords (map show (toList (1 :> 2 :> 3 :> End)))
  , show ((<^>) 7 2, (`minus` 1) 5, (+++ "!") "hey" == "hey!")
  ]

main = appendChan stdout out abort done
