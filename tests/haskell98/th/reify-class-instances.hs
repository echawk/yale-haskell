{-# LANGUAGE TemplateHaskell #-}
module Main where
import ReifyClassGen
main :: IO ()
main = do
  putStrLn $(cls ''Functor)
  putStrLn $(insts ''Show [t| Int |])
