-- The Ratio library.
module Main where

import Ratio

r :: Rational
r = 3 % 4

main = appendChan stdout (unlines [
  show (r, numerator r, denominator r, 6 % (-8) :: Rational),
  show (r + 1 % 4, r * r, r - 1, r / (1 % 2), recip (negate r), abs (negate r), signum (negate r)),
  show (compare r (2 % 3), r == 6 % 8, max r (4 % 5), fromRational r :: Double),
  show (truncate (7 % 2 :: Rational) :: Int, round (5 % 2 :: Rational) :: Int, floor ((-1) % 3 :: Rational) :: Int, properFraction ((-7) % 2 :: Rational) :: (Int, Rational)),
  show (approxRational (3.14159 :: Double) 0.001, approxRational (0.3333 :: Double) 0.001),
  show (toRational (1.25 :: Double), [1 % 2, 1 .. 2 :: Rational]),
  show (Just ((-1) % 3 :: Ratio Int), read "(-3) % 6" :: Rational, read " 2 % 4 " :: Ratio Int),
  show (fromIntegral (3 :: Int) :: Rational, realToFrac (0.5 :: Double) :: Rational, 2 ^^ (-3 :: Int) :: Rational)
  ]) abort done
