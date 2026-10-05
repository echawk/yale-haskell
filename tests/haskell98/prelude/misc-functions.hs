-- curry, uncurry, undefined, seq, ($!), realToFrac, until, asTypeOf,
-- gcd/lcm/(^)/(^^), and the Integral/RealFrac methods.
module Main where

lazyPair :: (Int, Int)
lazyPair = (1, undefined)

main = appendChan stdout (unlines [
  show (curry fst 'a' 'b', uncurry max (3, 9 :: Int), uncurry (++) ("ab", "cd")),
  show (fst lazyPair, const 5 (undefined :: Int) :: Int),
  show (seq (3 :: Int) "ok", (+ 1) $! (41 :: Int), length [undefined, undefined :: Int]),
  show (realToFrac (0.5 :: Float) :: Double, realToFrac (3 :: Int) :: Double),
  show (until (> 1000) (* 2) (1 :: Int), (3 :: Int) `asTypeOf` 4),
  show (gcd 12 (18 :: Int), lcm 4 (6 :: Integer), gcd 0 (5 :: Int), 2 ^ (10 :: Int) :: Integer, 2 ^^ (-2 :: Int) :: Double),
  show (divMod (-7) (2 :: Int), quotRem (-7) (2 :: Int), (-7) `mod` (2 :: Integer), even (4 :: Int), odd (4 :: Int)),
  show (properFraction (3.75 :: Double) :: (Int, Double), truncate (-2.5 :: Double) :: Int),
  show (map (\x -> round (x :: Double) :: Int) [0.5, 1.5, 2.5, -0.5, -1.5]),
  show (ceiling (2.1 :: Double) :: Int, floor (-2.1 :: Double) :: Int, fromIntegral (7 :: Int) / (2 :: Double)),
  show (subtract 3 (10 :: Int), negate 4 :: Int, abs (-3 :: Integer), signum (-2.5 :: Double)),
  show (toRational (0.75 :: Double), fromRational (toRational (1.25 :: Float)) :: Double)
  ]) abort done
