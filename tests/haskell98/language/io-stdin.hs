-- Reading standard input with getLine and getContents, and read.
module Main where

main :: IO ()
main = do
  name <- getLine
  nums <- getLine
  let total = sum (map read (words nums)) :: Int
  putStrLn ("name: " ++ name)
  putStrLn ("sum: " ++ show total)
  rest <- getContents
  putStrLn ("remaining lines: " ++ show (length (lines rest)))
