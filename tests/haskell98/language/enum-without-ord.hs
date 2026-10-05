-- In Haskell 98, Enum has no superclass, so a type can derive Enum
-- without Eq or Ord and still be used in arithmetic sequences.
module Main where

data Step = One | Two | Three deriving Enum

count :: (Enum a) => a -> a -> Int
count a b = length [a .. b]

out :: String
out = unlines [ show (count One Three), show (count Two Two)
              , show (length (enumFrom One)) ]

main = appendChan stdout out abort done
