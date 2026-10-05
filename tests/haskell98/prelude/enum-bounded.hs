-- The H98 Enum methods (succ, pred, toEnum, fromEnum) and Bounded for
-- the Prelude types, and Fractional enumerations.
module Main where

data Colour = Red | Green | Blue deriving (Eq, Ord, Enum)

main = appendChan stdout (unlines [
  show (succ 'a', pred 'b', toEnum 65 :: Char, fromEnum 'A'),
  show (succ (41 :: Int), pred (0 :: Integer), toEnum 7 :: Integer, fromEnum (9 :: Integer)),
  show (succ False, pred True, toEnum 0 :: Bool, fromEnum True, [False ..]),
  show (fromEnum (2.7 :: Double), toEnum 3 :: Double, succ (1.5 :: Float)),
  show (minBound :: Char, (maxBound :: Char) >= '\255', minBound :: Bool, maxBound :: Bool),
  show (minBound :: (), [minBound .. maxBound :: Bool], fromEnum ()),
  show ((maxBound :: Int) > 2147483646, (minBound :: Int) < -2147483647),
  show [1.0, 1.5 .. 3.0 :: Double],
  show [1.0 .. 3.5 :: Double],
  show [5.0, 4.0 .. 1.0 :: Float],
  show (map fromEnum "Hi", ['a' .. 'e'], ['a', 'c' .. 'i']),
  show [10, 8 .. 1 :: Int],
  show ([Red ..] == [Red, Green, Blue], [Blue, Green ..] == [Blue, Green, Red]),
  show (succ Red == Green, [Green .. Blue] == [Green, Blue])
  ]) abort done
