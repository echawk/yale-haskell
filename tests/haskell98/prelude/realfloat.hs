-- The RealFloat class: the H98 predicates and the atan2 method.
-- (SBCL traps on overflow and 0/0, so no NaN or infinity is created.)
module Main where
import Dialogue (stdout, appendChan, done, abort)

big :: Double
big = encodeFloat 1 1000

main = appendChan stdout (unlines [
  show (isNaN (1.0 :: Double), isInfinite (big :: Double), isInfinite (1.0 :: Float)),
  show (isNegativeZero (-0.0 :: Double), isNegativeZero (0.0 :: Double), isNegativeZero (-1.0 :: Float)),
  show (isDenormalized (1.0 :: Double), isIEEE (1.0 :: Double), isIEEE (1.0 :: Float)),
  show (floatRadix (1 :: Double), floatDigits (1 :: Double), floatRange (1 :: Double)),
  show (floatDigits (1 :: Float), floatRange (1 :: Float)),
  show (decodeFloat (0.5 :: Double), encodeFloat 3 (-1) :: Double, exponent (8 :: Double)),
  show (significand (8 :: Double), scaleFloat 3 (1 :: Double)),
  show (map (\(y, x) -> atan2 y x :: Double) [(1, 1), (1, -1), (-1, -1), (-1, 1), (0, -1), (1, 0), (0, 1)]),
  show (atan2 (-0.0) (-1) :: Double, atan2 0 0 :: Double)
  ]) abort done
