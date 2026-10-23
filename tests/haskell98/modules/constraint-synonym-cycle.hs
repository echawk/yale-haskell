module Main where
import CsynCycleB
main :: IO ()
main = checkI' (21 :: Int) >>= print
