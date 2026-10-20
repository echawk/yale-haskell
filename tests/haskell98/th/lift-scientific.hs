{-# LANGUAGE TemplateHaskell #-}
module Main (main) where
import Data.Scientific (scientific, Scientific)
import Language.Haskell.TH.Syntax (lift)
main :: IO ()
main = print ($(lift (scientific 314 (-2))) :: Scientific)
