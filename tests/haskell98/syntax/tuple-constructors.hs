-- (,), (,,), ... and () as constructors in expressions and patterns
-- (H98 report 3.8, 3.17).
module Main where
import Dialogue (stdout, appendChan, done, abort)

pair :: a -> b -> (a, b)
pair = (,)

triple :: Int -> (Int, Int, Int)
triple = (,,) 1 2

swap :: (a, b) -> (b, a)
swap ((,) x y) = (,) y x

sum3 :: (Int, Int, Int) -> Int
sum3 ((,,) a b c) = a + b + c

firsts :: [(Int, Char)] -> [Int]
firsts xs = [ a | (,) a _ <- xs ]

unit :: () -> String
unit () = "unit"

showPair :: (Int, Int) -> String
showPair (a, b) = show a ++ "/" ++ show b

result :: String
result = unlines
  [ showPair (pair 1 2)
  , show (sum3 (triple 3))
  , showPair (swap (5, 6))
  , unwords (map show (firsts (zipWith (,) [7, 8, 9] "abc")))
  , show (sum3 ((,,) 10 20 30))
  , unit ()
  , case (,,,) 'w' 'x' 'y' 'z' of (,,,) _ _ c _ -> [c]
  ]

main = appendChan stdout result abort done
