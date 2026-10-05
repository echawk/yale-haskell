-- Without a default declaration the default is (Integer, Double)
-- (Haskell 98 section 4.3.4), so these results are exact.
module Main where

big = 2 ^ 70                 -- monomorphism restriction + defaulting

out :: String
out = unlines [ show big
              , show (product [1 .. 21])
              , show (10 ^ 18 * 100) ]

main = appendChan stdout out abort done
