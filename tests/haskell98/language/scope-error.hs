-- A where-bound name is not in scope outside its equation.
module Main where
import Dialogue (stdout, appendChan, done, abort)

f :: Int -> Int
f x = y + x where y = 1

g :: Int -> Int
g x = y * x

main = appendChan stdout (show (f 1 + g 2)) abort done
