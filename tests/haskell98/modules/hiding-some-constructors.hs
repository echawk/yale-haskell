-- hiding (F(Q)) hides F and Q, not P (H98 5.3.1)
module Main (main) where
import HidingSomeConstructorsA hiding (F(Q))
main :: IO ()
main = print P
