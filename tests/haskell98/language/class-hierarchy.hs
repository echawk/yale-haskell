-- Superclass methods reachable from the standard numeric classes
-- (Haskell 98 section 6.4): Num gives show and ==, Real gives <,
-- Integral gives Enum's enumFromTo, Fractional gives Num's +, and
-- RealFrac gives truncate.  (Modern GHC needs (Eq a, Show a) added to
-- describe's context; the expected output was checked that way.)
module Main where
import Dialogue (stdout, appendChan, done, abort)

describe :: (Num a) => a -> String
describe x = if x == 0 then "zero" else show (x + 1)

smaller :: (Real a) => a -> a -> Bool
smaller x y = x < y

upTo :: (Integral a) => a -> [a]
upTo n = [1 .. n]

halfSum :: (Fractional a) => a -> a -> a
halfSum x y = (x + y) / 2

whole :: (RealFrac a) => a -> Int
whole = truncate

out :: String
out = unlines [ describe (0 :: Int), describe (41 :: Integer)
              , show (smaller (1 :: Int) 2, smaller (2.5 :: Double) 1)
              , show (sum (upTo (10 :: Integer)))
              , show (whole (halfSum 7 (8 :: Double))) ]

main = appendChan stdout out abort done
