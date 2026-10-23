module Main where
import CsynNestA
import CsynNestB
import Control.Monad.State (runState)
main :: IO ()
main = print (runState (warnTwice "x" >> pretty) 0)
