-- Guards in function equations and case alternatives, 'otherwise', and
-- falling through to the next equation when every guard fails.
module Main where

classify :: Int -> String
classify n
  | n < 0  = "negative"
  | n == 0 = "zero"
  | even n = "even"
classify n = "odd"          -- reached only when all guards above fail

sign :: Int -> Int
sign x = case x - 0 of
           d | d < 0     -> -1
             | d > 0     -> 1
             | otherwise -> 0

collatz :: Int -> Int
collatz n | n == 1    = 0
          | even n    = 1 + collatz (n `div` 2)
          | otherwise = 1 + collatz (3 * n + 1)

out :: String
out = unlines (map classify [-3, 0, 4, 7] ++ map (show . sign) [-9, 0, 9]
               ++ [show (collatz 27)])

main = appendChan stdout out abort done
