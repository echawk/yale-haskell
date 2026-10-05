-- Derived Show for records uses record syntax, and fields are shown at
-- precedence 0, so negative numbers are not parenthesised.
module Main where

data P = P { px :: Int, py :: Int } deriving Show
data Box = Box { content :: Maybe P } deriving Show

out :: String
out = unlines [ show (P 1 (-2)), show (Box (Just (P { py = 4, px = 3 }))) ]

main = appendChan stdout out abort done
