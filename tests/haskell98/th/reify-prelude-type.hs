{-# LANGUAGE TemplateHaskell #-}
module Main where
import ReifyMaybeGen
main :: IO ()
main = putStrLn $(r)
