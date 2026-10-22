{-# LANGUAGE RankNTypes #-}
module Main where
import GHC.Stack (HasCallStack)
g :: Show a => Int -> (HasCallStack => a -> String)
g n x = show n ++ show x
main = putStrLn (g 1 True)
