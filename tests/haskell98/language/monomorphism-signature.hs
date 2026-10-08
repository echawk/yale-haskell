-- The monomorphism restriction does not apply to bindings with a type
-- signature or to function bindings, so these are used at two types.
module Main where
import Dialogue (stdout, appendChan, done, abort)

plus :: (Num a) => a -> a -> a
plus = (+)

times x y = x * y           -- a function binding: generalised

out :: String
out = unlines [ show (plus (1 :: Int) 2, plus (1.5 :: Double) 2.5 == 4)
              , show (times (3 :: Integer) 4, times (0.5 :: Double) 4 == 2) ]

main = appendChan stdout out abort done
