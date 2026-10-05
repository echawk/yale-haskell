-- A non-tail recursion 100000 calls deep, which any H98 implementation
-- is expected to handle.
module Main where

count :: [Int] -> Int
count []       = 0
count (_ : xs) = 1 + count xs

main = appendChan stdout (show (count [1 .. 100000]) ++ "\n") abort done
