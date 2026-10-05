-- newtype declarations: construction, pattern matching, a
-- parameterised newtype, and deriving Eq and Ord.
module Main where

newtype Age = Age Int deriving (Eq, Ord)
newtype Wrap a = Wrap a

older :: Age -> Age -> Bool
older (Age a) (Age b) = a > b

unwrap :: Wrap a -> a
unwrap (Wrap x) = x

out :: String
out = unlines [ show (older (Age 30) (Age 20), Age 5 == Age 5, Age 1 < Age 2)
              , unwrap (Wrap "wrapped")
              , show (maximum [Age 3, Age 9, Age 4] == Age 9) ]

main = appendChan stdout out abort done
