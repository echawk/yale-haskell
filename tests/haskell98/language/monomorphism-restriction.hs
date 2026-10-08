-- Monomorphism restriction, rule 1 (Haskell 98 section 4.5.5): plus is
-- a simple pattern binding without a signature, so it is not
-- generalised, and using it at both Int and Double is a type error.
module Main where
import Dialogue (stdout, appendChan, done, abort)

plus = (+)

out :: String
out = show (plus (1 :: Int) 2) ++ show (plus (1.5 :: Double) 2)

main = appendChan stdout out abort done
