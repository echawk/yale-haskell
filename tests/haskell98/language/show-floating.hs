-- show for Double and Float gives the shortest representation that
-- reads back to the same value (Haskell 98 Prelude, via floatToDigits).
module Main where
import Dialogue (stdout, appendChan, done, abort)

out :: String
out = unlines [ show (3 :: Double), show (0.1 :: Double), show (1.5e10 :: Double)
              , show (0.01 :: Double), show (-2.5 :: Double), show (1 / 3 :: Double)
              , show (3.5 :: Float), show (0.1 :: Float)
              , show (12345.678 :: Double), show (1.0e-4 :: Double) ]

main = appendChan stdout out abort done
