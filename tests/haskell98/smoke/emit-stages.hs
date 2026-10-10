-- yale-haskell --emit: every stage of a small program (the output has
-- gensyms and addresses, so only the exit status is checked).
module Main where

data Shape = Circle Double | Square Double

area :: Shape -> Double
area (Circle r) = pi * r * r
area (Square s) = s * s

main :: IO ()
main = print (sum (map area [Circle 1, Square 2]))
