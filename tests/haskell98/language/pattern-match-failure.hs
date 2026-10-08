-- Applying a function to a value none of its equations match is a
-- runtime error (Haskell 98 section 4.4.3).
module Main where
import Dialogue (stdout, appendChan, done, abort)

data Color = Red | Green | Blue

name :: Color -> String
name Red   = "red\n"
name Green = "green\n"

main = appendChan stdout (concat (map name [Red, Green, Blue, Red])) abort done
