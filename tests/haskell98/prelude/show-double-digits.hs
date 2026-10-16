-- show on Double and Float gives the shortest digits that read back, as GHC's
-- (PreludeNumeric's floatToDigits: two fixes to the Report's version).
main :: IO ()
main = do
  mapM_ (\k -> print (2 ^^ k :: Double)) [-1074, -1060 .. 1023]
  mapM_ (\k -> print (2 ^^ k :: Float)) [-149, -140 .. 127]
  print [fromIntegral n / 7 :: Double | n <- [1 .. 30 :: Int]]
  print [1.0e-300, 5.0e-324, 1.7976931348623157e308, 0.1, 123.456, 1e22, 1e23 :: Double]
  print [0.1, 3.4028235e38, 1.0e-45, 16777216 :: Float]
  print (map (\x -> x * 1.1) [1 .. 20 :: Double])
