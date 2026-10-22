module Main (main) where
import GHC.Float
import Numeric (showHex)

main :: IO ()
main = do
  mapM_ (\d -> putStrLn (showHex (castDoubleToWord64 d) "")) [1.0, -2.5, 0, 1 / 0, 5.0e-324]
  print (map (castWord64ToDouble . castDoubleToWord64) [1.0, -2.5, 3.141592653589793, 1.0e-310])
  putStrLn (showHex (castFloatToWord32 1.5) "")
  print (castWord32ToFloat (castFloatToWord32 (-0.1)))
