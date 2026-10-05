-- import qualified ... as, together with hiding: the program defines
-- its own map and filter and reaches the Prelude's through P.
module Main where

import Prelude hiding (map, filter)
import qualified Prelude as P

map :: (a -> b) -> [a] -> [b]
map f xs = P.reverse (P.map f xs)

filter :: (a -> Bool) -> [a] -> [a]
filter p = P.filter (not . p)

out :: String
out = unlines [ unwords (P.map show (map (* 2) [1, 2, 3 :: Int]))
              , unwords (P.map show (filter even [1 .. 6 :: Int])) ]

main = appendChan stdout out abort done
