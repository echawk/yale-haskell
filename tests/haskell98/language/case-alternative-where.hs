-- Guarded case alternatives with their own where clause, and guarded
-- pattern bindings (Haskell 98 sections 3.13 and 4.4.3).
module Main where

classify :: [Int] -> String
classify xs = case xs of
  (y : ys) | s > 10    -> "big " ++ show s
           | otherwise -> "small " ++ show s
    where s = y + sum ys
  []                   -> "empty"

limit :: Int
limit | big       = 1000
      | otherwise = 10
  where big = length "abc" > 2

(lo, hi) | limit > 100 = (0, limit)
         | otherwise   = (limit, 0)

out :: String
out = unlines [ classify [5, 6], classify [1, 2], classify []
              , show limit, show (lo :: Int, hi :: Int) ]

main = appendChan stdout out abort done
