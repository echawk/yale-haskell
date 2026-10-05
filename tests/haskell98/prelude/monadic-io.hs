-- Monadic Prelude I/O: putStr, putStrLn, print, mapM_, getLine.
module Main where

main :: IO ()
main = do
  putStr "Name? "
  name <- getLine
  putStrLn ("Hello, " ++ name)
  mapM_ print [1, 2, 3 :: Int]
  print (length name)
