{-# LANGUAGE TemplateHaskell #-}
-- Expression splices running generators from an imported module
-- (doc/plans/TEMPLATE-HASKELL.md, milestone 2).
module Main where
import Language.Haskell.TH
import SpliceGen

cube :: Int -> Int
cube = $(power 3)

main :: IO ()
main = do
  print (cube 4)
  print ($(sel 2 3) ('a', "bee", True))
  putStrLn $greeting
  print (sum $(countTo 10))
  print $(condE (conE 'True) (litE (charL 'y')) (litE (charL 'n')))
