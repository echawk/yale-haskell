{-# LANGUAGE TemplateHaskell #-}
-- $( [| e |] ) is e, also with this module's own names in e.
import Language.Haskell.TH

data Shape = Circle Double | Rect Double Double deriving Show

area :: Shape -> Double
area (Circle r) = 3 * r * r
area (Rect w h) = w * h

main :: IO ()
main = do
  print ($( [| map (* 2) [1, 2, 3 :: Int] |] ) == map (* 2) [1, 2, 3])
  print ($( [| let xs = "abc" in (reverse xs, length xs) |] ))
  print ($( [| \(a, b) -> if a then b + 1 else negate b |] ) (True, 41 :: Int))
  print ($( [| case Rect 2 3 of { Circle _ -> 0; Rect w h -> w * h } |] ))
  print ($( [| [ (i, c) | i <- [1 :: Int .. 3], c <- "xy", i < 3 ] |] ))
  print ($( [| area (Circle 1) + area (Rect 2 5) |] ))
  print ($( [| do { x <- Just 3; y <- Just (4 :: Int); return (x * y) } |] ))
  print ($( [| (subtract 1, (`div` 2)) |] ) `seq` "sections")
  print ($( [| foldr (\x acc -> x : take 2 acc) [] [1 .. 10 :: Int] |] ))
  e <- runQ [| ("lifted", 'c', [True]) |]
  putStrLn (pprint e)
  let s = "outer string"
  e2 <- runQ [| s ++ "!" |]
  putStrLn (pprint e2)
