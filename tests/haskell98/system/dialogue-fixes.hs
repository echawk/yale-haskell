-- Runtime fixes seen through the Prelude's I/O functions:
--   * writeFile truncates an existing, longer file;
--   * getEnv of an unset variable raises an IOError.
module Main where

import System
import Directory

file :: String
file = "/tmp/yale-haskell-dialogue-fixes.txt"

main :: IO ()
main = do
  writeFile file "a long first line\n"
  writeFile file "short\n"
  s <- readFile file
  putStr ("contents: " ++ s)
  removeFile file
  r <- catch (getEnv "YALE_HASKELL_SURELY_UNSET_VARIABLE")
             (\e -> return "failure continuation")
  putStrLn ("unset: " ++ r)
