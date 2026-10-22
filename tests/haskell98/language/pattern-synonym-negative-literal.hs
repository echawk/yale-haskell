{-# LANGUAGE PatternSynonyms #-}
module Main where
data S = S Int Integer deriving Show
pattern Small :: Int -> S
pattern Small u = S u (-1)
f (Small u) = u
f _ = 0
main = print (Small 3) >> print (f (S 4 (-1)), f (S 5 2))
