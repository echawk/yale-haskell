-- A thunk that depends on itself is detected at run time (<<loop>>,
-- exit status 1) after the output produced so far (Haskell 1.2).
module Main where

data Box = Box Integer

unBox :: Box -> Integer
unBox (Box n) = n

main = appendChan stdout "before the loop\n" abort (
       let b = Box (unBox b + 1)
       in appendChan stdout (show (unBox b)) abort done)
