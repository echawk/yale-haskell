-- import Prelude hiding (...) lets the program define names the
-- Prelude also exports.
module Main where

import Prelude hiding (words, filter)

words :: String -> [String]
words s = case break (== ',') s of
            (w, [])       -> [w]
            (w, _ : rest) -> w : words rest

filter :: (a -> Bool) -> [a] -> [a]
filter p xs = [x | x <- xs, not (p x)]

out :: String
out = unlines [ unwords (words "a,b c,d"), show (length (words "x"))
              , unwords (map show (filter odd [1 .. 6 :: Int])) ]

main = appendChan stdout out abort done
