{-# LANGUAGE QuasiQuotes #-}
module Main where
import QQGen

[defs|one two three|]

name :: String
name = "world"

main :: IO ()
main = do
  putStrLn [str|a raw string with "quotes" and \backslashes|]
  putStrLn [fmt|Hello #{name}!|]
  print (one + two + three)
  print [x | x <- [1, 2, 3 :: Int]]
