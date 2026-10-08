-- reads for Int and Integer (a fast path for plain decimals) must give
-- exactly what the Report's readSigned readDec gives.

import Numeric (readSigned, readDec)

inputs :: [String]
inputs = [ "42", "  42", "-42", " -42 rest", "- 42", "--42", "(42)", "(-42)"
         , " ( 42 ) x", "42abc", "42 abc", "42.5", "42.x", "42.", "42e3"
         , "42E", "42ex", "-", "", "abc", "007", "-0", "\t\n9"
         , "123456789012345678901234567890", "-98765432109876543210 z" ]

main :: IO ()
main = do
  print (and [ (reads s :: [(Int, String)]) == readSigned readDec s
             | s <- take 23 inputs ])
  print (and [ (reads s :: [(Integer, String)]) == readSigned readDec s
             | s <- inputs ])
  print [ reads s :: [(Integer, String)] | s <- inputs ]
  print (read " 17 " + read "(-3)" :: Int)
