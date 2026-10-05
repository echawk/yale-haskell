-- Tail recursion runs in constant stack: a million-iteration loop
-- whose accumulator is forced by a guard each step.
module Main where

loop :: Int -> Int -> Int
loop acc n | n == 0    = acc
           | acc < 0   = 0
           | otherwise = loop (acc + n `mod` 7) (n - 1)

down :: Int -> Int
down 0 = 0
down n = down (n - 1)

out :: String
out = unlines [ show (loop 0 1000000), show (down 1000000) ]

main = appendChan stdout out abort done
