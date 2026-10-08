module Main where
square :: Int -> Int
square x = x * x
data Shape = Circle Double | Rect Double Double deriving Show
area :: Shape -> Double
area (Circle r) = pi * r * r
area (Rect w h) = w * h
main = print (map square [1..5])
