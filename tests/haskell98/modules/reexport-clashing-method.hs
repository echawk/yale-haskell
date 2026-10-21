module Main (main) where
import ReexportClashB as X (putStr)
main :: IO ()
main = X.putStr True
