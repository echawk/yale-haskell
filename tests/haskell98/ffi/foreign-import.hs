module Main where
import Data.Int

foreign import ccall "math.h sin" c_sin :: Double -> Double
foreign import ccall unsafe "pow" c_pow :: Double -> Double -> Double
foreign import ccall "stdlib.h labs" labs :: Int -> Int
foreign import ccall "toupper" c_toupper :: Int32 -> Int32
foreign import ccall "isdigit" isDigitC :: Char -> Bool
foreign import ccall "getpid" getpid :: IO Int32
foreign import ccall "sqrtf" sqrtf :: Float -> Float

main :: IO ()
main = do
  print (c_sin 0.5, c_pow 2 10, labs (-42), sqrtf 2)
  print (map c_toupper [97, 98, 99], map isDigitC "a1b2")
  pid <- getpid
  print (pid > 0)
  let foreign = 3 :: Int
  print foreign
