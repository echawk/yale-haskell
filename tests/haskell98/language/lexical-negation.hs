{-# LANGUAGE LexicalNegation #-}
f :: Int -> Int
f x = x * 2

main :: IO ()
main = do
  print (f -3)
  print (map (subtract 1) [1, 2 :: Int], (- 1) (5 :: Int), let x = 4 :: Int in -x)
  print (abs -2 + 1 :: Int)
  print (negate 3 - 1 :: Int, 3 - 1 + 2 :: Int)
