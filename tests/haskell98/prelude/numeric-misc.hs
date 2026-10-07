module Main where

import Numeric
import Char

main = appendChan stdout (unlines [
  show (truncate (1e20 :: Double) :: Integer),
  show (decodeFloat (0.1 :: Double)),
  show (floatDigits (1 :: Float), floatRange (1 :: Double), floatRadix (1::Double)),
  show (atan2 1 (-1) :: Double),
  show (isNaN (0.5 :: Double), isInfinite (1e300 * 1e10 :: Double)),
  show (fromIntegral (2 ^ 40 :: Integer) :: Int),
  show (read "1e5" :: Double, read " 12 " :: Int, read "-3" :: Int),
  show (read "[1,2,3]" :: [Int], read "(1,\"a\")" :: (Int, String)),
  showHex (255 :: Int) "" ++ " " ++ showOct (64 :: Int) "" ++ " " ++ showFFloat (Just 2) (3.14159 :: Double) "",
  showEFloat (Just 3) (1234.5 :: Double) "" ++ " " ++ showGFloat (Just 2) (0.01 :: Double) "",
  show (fst (head (readHex "ff" :: [(Int,String)]))),
  show (floatToDigits 10 (0.15625 :: Double)),
  show (map toUpper "héllo", ord 'é', chr 233),
  show (digitToInt 'f', intToDigit 11, isHexDigit 'a'),
  show (1.0e-2 :: Double, 1.5e10 :: Double, 123456.789 :: Double, 0.1 + 0.2 :: Double),
  show (fromIntegral (3 :: Int) / 2 :: Float),
  show (round (2.5 :: Double) :: Int, round (3.5 :: Double) :: Int, round (-2.5 :: Double) :: Int),
  show (ceiling (2.1 :: Double) :: Int, floor (-2.1 :: Double) :: Int, truncate (-2.9 :: Double) :: Int),
  show (divMod (-7) 2 :: (Int,Int), quotRem (-7) 2 :: (Int,Int)),
  show (gcd 12 18 :: Int, lcm 4 6 :: Int, 2 ^^ (-2) :: Double),
  show (toRational (0.75 :: Double)),
  show (sqrt 2 :: Float),
  show (exp 1 :: Double),
  show (showsPrec 7 (-5 :: Int) ""),
  show (lex " hello world", lex "123abc", lex "<= x"),
  show (reads "12abc" :: [(Int,String)]),
  show 'x' ++ show "a\tb\200\&5" ++ show '\n'
  ]) abort done
