{-# LANGUAGE TemplateHaskell #-}
-- Generators written with quotes (the TH paper's power, printf, and its
-- scoping example: the spliced x is QuoteGen's, not this module's).
module Main where
import QuoteGen (power, printf, g, sel)

x :: String
x = "Main's x, not QuoteGen's"

main :: IO ()
main = do
  print ($(power 3) (2 :: Int))
  putStrLn ($(printf "%d apples and %s, %d of them") 3 "pears" 99)
  print $(g 5)
  putStrLn x
  print ($(sel 3 3) ('a', 'b', 'c'))
