-- Data.Scientific (scientific 0.3.8.0, imported): its documented examples,
-- then conversions and formatting.
import Data.Scientific
import Data.Hashable (hash)
import Text.ParserCombinators.ReadP (readP_to_S)
main = do
  let x = scientific 1 2; y = scientific 100 0
  print (x == y, hash x == hash y)
  print (read " ( ((  -1.0e+3 ) ))" :: Scientific)
  print (readP_to_S scientificP "3")
  print (readP_to_S scientificP "3.0e2")
  print (readP_to_S scientificP "+3.0e+2")
  print (readP_to_S scientificP "-3.0e-2")

  -- conversions
  let xs = [scientific 15 (-1), scientific 123456789 (-3), 1.0e-20, 12e7, -0.5, scientific 0 0] :: [Scientific]
  print xs
  print (map (toRealFloat :: Scientific -> Double) xs, map floatingOrInteger xs :: [Either Double Integer])
  print (map coefficient xs, map base10Exponent xs, normalize (scientific 1200 0))
  print (fromFloatDigits (3.25 :: Double), read "  -1.0e+3" :: Scientific, toBoundedInteger (scientific 42 1) :: Maybe Int)
  print (formatScientific Fixed (Just 2) 3.14159, formatScientific Exponent Nothing 1234.5, scientific 1 2 + 0.5, recip (4 :: Scientific))
  print (hash (scientific 1 2) == hash (scientific 100 0), isInteger 3.0, sciToInt 7)
 where sciToInt :: Scientific -> Int
       sciToInt s = maybe 0 id (toBoundedInteger s)
