module Main where

inf, nan :: Double
inf = 1 / 0
nan = 0 / 0

main = appendChan stdout (unlines [
  show inf, show (-inf), show nan,
  show (isInfinite inf, isNaN nan, isNaN inf, isInfinite nan),
  show (nan == nan, nan < 1, inf > 1e308),
  show (1e300 * 1e10 :: Double),
  show (sqrt (-1) :: Double),
  show (inf - inf),
  show (truncate (1e10 :: Double) :: Int),
  show (read "Infinity" :: Double),
  show (1e-320 :: Double, isDenormalized (1e-320 :: Double)),
  show (isNegativeZero (-0.0 :: Double), -0.0 :: Double),
  show (1/(-0.0) :: Double),
  show (2 ** 0.5 :: Double, 0 ** 0 :: Double),
  show (1e2 :: Double, 1E-2 :: Double, 5e0 :: Double)
  ]) abort done
