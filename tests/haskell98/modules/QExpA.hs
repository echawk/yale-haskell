-- Helper for qualified-export.hs.
module QExpA (choice, other) where

choice :: [Int] -> Int
choice = sum

other :: Int
other = 2
