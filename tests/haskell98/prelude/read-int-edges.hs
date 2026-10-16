-- reads of Int and Integer (PreludeNumeric's readSignedDec fast path) agree with GHC
main :: IO ()
main = do
  print (map read ["0", "42", "-17", "  9", "007", "123456789012"] :: [Int])
  print (reads "12abc" :: [(Int, String)])
  print (reads "12.5" :: [(Int, String)])
  print (reads "12e3" :: [(Int, String)])
  print (reads "12. x" :: [(Int, String)])
  print (reads "-5 rest" :: [(Int, String)])
  print (reads "(3)" :: [(Int, String)])
  print (reads "0x1F" :: [(Int, String)])
  print (read "99999999999999999999" :: Integer)
  print (reads "" :: [(Int, String)])
