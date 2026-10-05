-- Derived Bounded instances, and Bounded for tuples.
module Main where

data Suit = Clubs | Diamonds | Hearts | Spades deriving (Eq, Ord, Enum, Bounded)

data Pair = Pair Bool Char deriving (Eq, Bounded)

main = appendChan stdout (unlines [
  show (fromEnum (maxBound :: Suit), minBound == Clubs),
  show (maxBound == Pair True maxBound, (minBound :: (Bool, Bool)))
  ]) abort done
