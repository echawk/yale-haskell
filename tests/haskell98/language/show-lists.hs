-- show for lists, nested lists, tuples, strings and characters
-- (Haskell 98 Prelude): no spaces after commas.
module Main where

out :: String
out = unlines [ show [1, 2, 3 :: Int]
              , show [[1], [], [2, 3 :: Integer]]
              , show [-1, 0 :: Int]
              , show ("ab", 'c', [True, False])
              , show [(1 :: Int, "x")]
              , show ([] :: [Int])
              , show [(), ()]
              , show "tab\there"
              , show ['a', '\n'] ]

main = appendChan stdout out abort done
