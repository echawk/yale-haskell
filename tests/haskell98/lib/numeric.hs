-- The Numeric library.  (Rounding ties are avoided: the Report rounds
-- half up, GHC rounds half to even.)
module Main where

import Numeric
import Char (intToDigit)

main = appendChan stdout (unlines [
  showHex (255 :: Int) "" ++ " " ++ showOct (64 :: Int) "" ++ " " ++ showInt (1234 :: Integer) "",
  showIntAtBase (2 :: Int) intToDigit 10 "" ++ " " ++ showIntAtBase (36 :: Integer) (\d -> "0123456789abcdefghijklmnopqrstuvwxyz" !! d) 1295 "",
  show (map (\x -> showEFloat (Just 2) (x :: Double) "") [0, 1234.5, 0.000123, -2.5]),
  show (map (\x -> showFFloat (Just 2) (x :: Double) "") [0, 1234.5, 0.0051, 0.016, -2.5]),
  show (map (\x -> showGFloat (Just 3) (x :: Double) "") [0.05, 123.456, 1.0e9]),
  show (map (\x -> showEFloat Nothing (x :: Double) "") [1, 0.1, 123]),
  show (map (\x -> showFFloat Nothing (x :: Double) "") [1, 0.1, 1.0e-4, 1.0e22]),
  show (showFloat (3.0e-2 :: Double) "", showFloat (12.5 :: Float) "", showFFloat (Just 0) (2.6 :: Double) ""),
  show (floatToDigits 10 (0.3 :: Double), floatToDigits 10 (1.0e23 :: Double), floatToDigits 2 (0.75 :: Float)),
  show (showSigned showInt 7 (-5 :: Int) "", showSigned showInt 0 (-5 :: Int) ""),
  show (readHex "ff rest" :: [(Int, String)], readOct "777" :: [(Integer, String)], readDec "12x" :: [(Int, String)]),
  show (readSigned readDec "-12 z" :: [(Int, String)], readFloat "2.5e1x" :: [(Double, String)]),
  show (readInt 2 (`elem` "01") (\c -> fromEnum c - fromEnum '0') "1011" :: [(Int, String)]),
  show (lexDigits "123abc", fromRat (7 / 2) :: Double, fromRat (1 / 3) :: Float)
  ]) abort done
