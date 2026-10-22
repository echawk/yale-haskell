{-# LANGUAGE TypeFamilies #-}
module Main (main) where
import QualifiedReexportA (P(P), toList)
main :: IO ()
main = print (toList (P 1 2))
