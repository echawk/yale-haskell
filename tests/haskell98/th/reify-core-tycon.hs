{-# LANGUAGE TemplateHaskell #-}
module Main where
import ReifyTyconGen
main :: IO ()
main = putStrLn $(r)
