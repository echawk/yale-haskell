-- H98 Show/Read formats for the Prelude types: lists without spaces,
-- shortest-digits floating point, negative numbers in parentheses,
-- strings and characters, tuples, Rational.
module Main where

main = appendChan stdout (unlines [
  show [1, 2, 3 :: Int],
  show [[1], [], [2, 3 :: Integer]],
  show (0.1 :: Double, 1.0e-2 :: Double, 1.0e7 :: Double, 1234567.0 :: Double),
  show (123456.789 :: Double, 1.0e-300 :: Double, 2 / 3 :: Double, -0.0 :: Double),
  show (3.5 :: Float, 1 / 3 :: Float, sqrt 2 :: Float, 100 :: Float),
  show (Just (-1.5 :: Double), [-1, 2 :: Int], (-3 :: Integer, -4.0 :: Float)),
  showsPrec 7 (-5 :: Int) "" ++ " " ++ showsPrec 6 (-5 :: Int) "",
  show "tab\there \"q\" \\ \234x \SOH",
  show ['a', '\'', '\n', '\DEL', '\200'],
  show (toRational (0.75 :: Double), (-3) / (4 :: Rational)),
  show (2 ^ (70 :: Int) :: Integer, -(2 ^ (70 :: Int)) :: Integer),
  show ((), ((), [()])),
  show (read "  42 " :: Int, read "-7" :: Int, read "(-7)" :: Integer, read "3.25" :: Double),
  show (read "1e3" :: Double, read "-2.5e-3" :: Double, read "[1,2, 3]" :: [Int]),
  show (read "('x',\"y\\n\",True)" :: (Char, String, Bool)),
  show (read "(1,2)" :: (Int, Int), read "[(1,[True])]" :: [(Int, [Bool])]),
  show (reads "12 rest" :: [(Int, String)], reads "nope" :: [(Int, String)]),
  show (lex "  hello world", lex "<= x", lex "'a' b", lex "12.5e3x", lex "\"s\" t", lex ""),
  show (read "3 % 4" :: Rational)
  ]) abort done
