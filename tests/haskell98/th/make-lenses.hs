{-# LANGUAGE TemplateHaskell, RankNTypes #-}
module Main where
import LensGen

data Point = Point { _px :: Int, _py :: Int, _label :: String } deriving Show

makeLenses ''Point

main :: IO ()
main = do
  let p = Point 1 2 "a"
  print (view px p, view label p)
  print (set py 20 p)
  print (over px (+ 100) p)
