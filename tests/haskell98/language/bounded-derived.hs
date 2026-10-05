-- Derived Bounded (Haskell 98 section 10.3) for an enumeration and a
-- single-constructor type, plus the Prelude instances for Char, Bool
-- and tuples.  (maxBound :: Char depends on Unicode, so it is left out.)
module Main where

data Suit = Clubs | Diamonds | Hearts | Spades deriving (Eq, Enum, Bounded)
data Pair = Pair Bool Suit deriving Bounded

suitName :: Suit -> Char
suitName s = "CDHS" !! fromEnum s

out :: String
out = unlines [ map suitName [minBound .. maxBound]
              , [suitName minBound, suitName maxBound]
              , case maxBound of Pair b s -> show b ++ [suitName s]
              , show (fromEnum (minBound :: Char), maxBound :: Bool)
              , show (fst (minBound :: (Bool, Int)), snd (maxBound :: (Int, Bool))) ]

main = appendChan stdout out abort done
