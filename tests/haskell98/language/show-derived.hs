-- Derived Show (Haskell 98 section 10.4): nullary constructors without
-- parentheses, arguments parenthesised at precedence 11, negative
-- numbers parenthesised, lists, tuples and strings inside.
module Main where

data Color = Red | Green deriving Show
data T = A | B Int | C T T | D [Int] (Int, Char) String | E Color
  deriving Show
data Tree a = Leaf | Node (Tree a) a (Tree a) deriving Show

out :: String
out = unlines [ show Red
              , show (B 3), show (B (-3))
              , show (C A (B 2))
              , show (D [1, -2] (3, 'x') "s\"q")
              , show (E Green)
              , show (Node Leaf (-1.5 :: Double) (Node Leaf 2 Leaf))
              , show [Just' A, Nothing']
              , showsPrec 11 (B 1) "" ]

data Opt a = Nothing' | Just' a deriving Show

main = appendChan stdout out abort done
