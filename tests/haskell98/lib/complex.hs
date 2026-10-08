-- The Complex library.  Outputs avoid the last few digits, which
-- depend on the libm.
module Main where
import Dialogue (stdout, appendChan, done, abort)

import Complex

z, w :: Complex Double
z = 3 :+ 4
w = 1 :+ (-2)

approx :: Complex Double -> (Double, Double)
approx (x :+ y) = (fromIntegral (round (x * 1000)) / 1000, fromIntegral (round (y * 1000)) / 1000)

main = appendChan stdout (unlines [
  show (z, w, realPart z, imagPart w, conjugate z),
  show (z + w, z - w, z * w, z / w, negate z),
  show (magnitude z, abs z, signum z, fromInteger 2 :: Complex Double),
  show (phase (0 :+ 0 :: Complex Double), phase (0 :+ 1 :: Complex Double) * 2 == pi),
  show (approx (mkPolar 2 (pi / 2)), approx (cis pi), polar (0 :+ 2 :: Complex Double)),
  show (approx (sqrt z), approx (sqrt ((-4) :+ 0)), approx (exp (0 :+ pi)), approx (log z)),
  show (approx (sin w), approx (cos w), approx (z ** 2)),
  show (Just (1.5 :+ 2 :: Complex Float), [0 :+ (-1) :: Complex Double], z == 3 :+ 4),
  show (read "2.0 :+ (-1.0)" :: Complex Double)
  ]) abort done
