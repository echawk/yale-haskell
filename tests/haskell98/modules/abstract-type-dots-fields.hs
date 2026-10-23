module Main where
import AbsFieldsA (WE(WE))
import AbsFieldsW (WE(..))
main :: IO ()
main = print (nonFatal (WE [1] [2]), tcW (WE [5] []))
