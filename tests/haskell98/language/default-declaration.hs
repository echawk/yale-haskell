-- An explicit default declaration (Haskell 98 section 4.3.4) resolves
-- ambiguous numeric types: here to Integer, so 2^70 does not overflow,
-- and to Double for Fractional.
module Main where

default (Integer, Double)

out :: String
out = unlines [ show (2 ^ 70)
              , show (product [1 .. 21])
              , show (truncate (7 / 2))
              , show (length "abc" + 1) ]

main = appendChan stdout out abort done
