-- Defaulting applies to type variables that are ambiguous inside an
-- expression with a type signature: the exponents of ^ below.
module Main where

out :: String
out = unlines [ show (2 ^ 10 :: Int)
              , show (length (replicate' (3 ^ 2) 'x') :: Int) ]
  where replicate' n x = take n (repeat x)

main = appendChan stdout out abort done
