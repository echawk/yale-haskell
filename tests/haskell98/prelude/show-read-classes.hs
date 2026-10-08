-- Show and Read (H98 Report 6.3.3, 10.4): derived instances, the
-- Prelude instances, tuples, a Show instance defining only `show',
-- and the precedence rules for infix constructors and negative numbers.
module Main where

import Ratio

infixr 5 :+:
data T = A | B Int | C T T | Int :+: T deriving (Show, Read, Eq)

newtype N = N Int deriving (Show, Read, Eq)

data P = P
instance Show P where
  show _ = "pee"

main = do
  print (B (-3))
  print (Just (-2 :: Int))
  print [Left 1, Right 'x' :: Either Int Char]
  print (C A (B 1))
  print (1 :+: 2 :+: A)
  print (N 5)
  print [P, P]
  print (showsPrec 11 P "")
  print ((1 :: Int, 'a', "s"), (True, LT, ()))
  print (read "(1,'a',\"s\")" :: (Int, Char, String))
  print (read " [ B 2 , C A A ] " :: [T])
  print (read "3 :+: (4 :+: A)" :: T)
  print (read "(N 7)" :: N)
  print (read "Just (Left 4)" :: Maybe (Either Int Bool))
  print (3 % 4 :: Rational)
  print (read "3 % 4" :: Rational)
  print (show 2.5, show (-1 :: Integer))
  print (reads "12 rest" :: [(Int, String)])
