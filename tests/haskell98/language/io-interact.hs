-- interact: the program is a function from all of stdin to stdout.
module Main where

main :: IO ()
main = interact (unlines . zipWith number [1 ..] . map reverse . lines)
  where number n l = show n ++ ": " ++ l
