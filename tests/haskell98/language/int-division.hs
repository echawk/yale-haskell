-- quot/rem truncate toward zero, div/mod toward negative infinity
-- (Report 6.4.2), for Int and Integer, including negative operands.

pairs :: [(Int, Int)]
pairs = [(7, 2), (-7, 2), (7, -2), (-7, -2), (6, 3), (-6, 3), (0, 5)]

big :: Integer
big = 12345678901234567890123

main :: IO ()
main = do
  print [ (quot a b, rem a b, div a b, mod a b) | (a, b) <- pairs ]
  print [ (quotRem a b, divMod a b) | (a, b) <- pairs ]
  print [ (quot a b, rem a b, div a b, mod a b)
        | (a, b) <- [ (toInteger x, toInteger y) | (x, y) <- pairs ] ]
  print (divMod (negate big) 1000000007, quotRem (negate big) 1000000007)
  print (and [ div a b * b + mod a b == a && quot a b * b + rem a b == a
             | a <- [-20 .. 20 :: Int], b <- [-7 .. -1] ++ [1 .. 7] ])
