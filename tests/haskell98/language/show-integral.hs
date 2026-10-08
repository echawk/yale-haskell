-- show for Int and Integer: negative numbers parenthesised above
-- precedence 6, as showSigned does; minBound; big Integers.
module Main where
main = do
  print (Just (-3 :: Int), [-3, 4 :: Int], Just (-12345678901234567890 :: Integer), (-5 :: Int))
  print (minBound :: Int, showsPrec 7 (-2 :: Int) "", showsPrec 6 (-2 :: Integer) "")
