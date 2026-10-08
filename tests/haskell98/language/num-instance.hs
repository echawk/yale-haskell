-- A user-defined Num instance (superclasses Eq and Show in Haskell
-- 98); numeric literals at the new type go through fromInteger.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data V = V Int Int deriving (Eq, Show)

instance Num V where
  V a b + V c d = V (a + c) (b + d)
  V a b * V c d = V (a * c) (b * d)
  negate (V a b) = V (negate a) (negate b)
  abs (V a b)    = V (abs a) (abs b)
  signum (V a b) = V (signum a) (signum b)
  fromInteger n  = V (fromInteger n) (fromInteger n)

out :: String
out = unlines [ show (V 1 2 + 10), show (V 3 4 * 2 - 1), show (sum [V 1 1, V 2 2]) ]

main = appendChan stdout out abort done
