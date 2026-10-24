{-# LANGUAGE TemplateHaskell #-}
-- addTopDecls from an expression splice and from a module finalizer.
module Main where

import TopDeclsGen

countedTwice

main :: IO ()
main = do
  print $(squareOf 7)
  print ($(squareOf 3) + 1)
  putStrLn finalized
