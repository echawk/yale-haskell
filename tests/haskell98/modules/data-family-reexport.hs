{-# LANGUAGE TypeFamilies #-}
module Main (main) where
import DataFamB (Vec(..), sizeOf)
main :: IO ()
main = print (sizeOf (VInt [1, 2, 3]))
