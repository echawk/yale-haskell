-- LambdaPi's module is LP, with main in it (GHC needs -main-is LP); this
-- wrapper is the program's Main (tools/conformance/typecheckers.py).
module Main (main) where
import qualified LP
main :: IO ()
main = LP.main
