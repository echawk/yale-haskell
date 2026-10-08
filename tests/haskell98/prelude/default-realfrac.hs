-- Defaulting a type variable whose only context is RealFrac (from
-- round/truncate applied to a fractional literal) must pick Double.
module Main where
import Dialogue (stdout, appendChan, done, abort)

main = appendChan stdout (unlines [
  show (round 2.5 :: Int, truncate 7.9 :: Int, floor (-0.5) :: Integer)
  ]) abort done
