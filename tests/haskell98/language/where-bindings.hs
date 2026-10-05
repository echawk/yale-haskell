-- where bindings: scope over all guards, pattern bindings, nested
-- where, and shadowing of a top-level name.
module Main where

divide :: Int -> Int -> String
divide a b
  | r == 0    = show a ++ " = " ++ show q ++ " * " ++ show b
  | otherwise = show a ++ " = " ++ show q ++ " * " ++ show b ++ " + " ++ show r
  where (q, r) = a `divMod` b

area :: Int -> Int -> Int
area w h = total
  where total  = inner + border
        inner  = (w - 2) * (h - 2)
        border = perim - 4
          where perim = 2 * (w + h)

x :: Int
x = 100

shadow :: Int -> Int
shadow y = x + y where x = 1

out :: String
out = unlines [divide 17 5, divide 12 4, show (area 5 4), show (shadow 2), show x]

main = appendChan stdout out abort done
