{-# LANGUAGE TemplateHaskell #-}
module Main where
import ReifyTypeGen
main :: IO ()
main = putStrLn $(r)
