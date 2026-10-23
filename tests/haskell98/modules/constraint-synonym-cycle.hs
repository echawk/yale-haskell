module Main where
import CsynCycleB
import Control.Monad.State (runState)
main :: IO ()
main = print (runState (checkI' (21 :: Int)) 5)
