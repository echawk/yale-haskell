-- Tuples: construction and matching up to seven components, nested
-- tuples, fst/snd, zip/unzip, and tuple equality and ordering.
module Main where

seven :: (Int, Char, Bool, String, Int, Char, Bool)
seven = (1, 'b', True, "four", 5, '6', False)

describe :: (Int, Char, Bool, String, Int, Char, Bool) -> String
describe (a, b, c, d, e, f, g) = show a ++ [b] ++ show c ++ d ++ show e ++ [f] ++ show g

swap :: (a, b) -> (b, a)
swap (x, y) = (y, x)

out :: String
out = unlines [ describe seven
              , show (swap (1 :: Int, "one"))
              , show (fst (snd (1 :: Int, (2 :: Int, 3 :: Int))))
              , case unzip (zip [1, 2, 3 :: Int] "abc") of (ns, cs) -> show (sum ns) ++ cs
              , show ((1, 'a') == (1 :: Int, 'a'), (2, "b") < (2 :: Int, "c"), (3, 0) > (2 :: Int, 9 :: Int)) ]

main = appendChan stdout out abort done
