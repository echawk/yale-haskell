-- A thunk that depends on itself is detected at run time: the program
-- stops with a <<loop>> runtime error (exit status 1) after the output
-- produced so far.  The cycle goes through a lazy data structure so that
-- the compiler cannot reject it at compile time.
module Main where

data Box = Box Integer

unBox :: Box -> Integer
unBox (Box n) = n

main :: IO ()
main = do
  putStrLn "before the loop"
  let b = Box (unBox b + 1)
  print (unBox b)
  putStrLn "not reached"
