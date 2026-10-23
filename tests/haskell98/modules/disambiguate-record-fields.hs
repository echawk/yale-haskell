{-# LANGUAGE RecordWildCards #-}
module Main where
import qualified DisambigFieldsA as Graph

f :: Graph.E -> Int
f Graph.E { source = a, target = b } = a + b

g :: Int -> Graph.E
g n = Graph.E { source = n, target = 2 }

main :: IO ()
main = print (f (g 1), [ a | Graph.E { source = a } <- [g 5] ])
