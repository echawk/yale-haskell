{-# LANGUAGE TemplateHaskell #-}
module Main where
import ReifyFixGen
main :: IO ()
main = putStrLn $(fixityOf '(+))
