{-# LANGUAGE TemplateHaskell #-}
module Main where
import QueryGen

main :: IO ()
main = putStrLn $(info)
