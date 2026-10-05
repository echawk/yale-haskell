-- case expressions: constructor, literal, string and character
-- patterns, wildcards, guards in alternatives, top-to-bottom matching,
-- case on tuples, nested case.
module Main where

data Shape = Circle Int | Rect Int Int | Tri Int Int Int

describe :: Shape -> String
describe s = case s of
  Circle 0          -> "point"
  Circle r          -> "circle " ++ show r
  Rect w h | w == h -> "square " ++ show w
  Rect w h          -> "rect " ++ show w ++ "x" ++ show h
  _                 -> "other"

greet :: String -> String
greet "hello"       = "hi"
greet ('b':'y':_)   = "goodbye"
greet [c]           = "char " ++ [c]
greet _             = "?"

zipCase :: [Int] -> [Int] -> String
zipCase xs ys = case (xs, ys) of
  ([], [])     -> "both empty"
  (_:_, [])    -> "left longer"
  ([], _:_)    -> "right longer"
  (a:as, b:bs) -> case a == b of
                    True  -> "same, " ++ zipCase as bs
                    False -> "differ"

out :: String
out = unlines (map describe [Circle 0, Circle 2, Rect 3 3, Rect 2 5, Tri 1 1 1]
               ++ map greet ["hello", "bye now", "x", "what"]
               ++ [zipCase [1,2] [1,2,3], zipCase [1] [2], zipCase [] []])

main = appendChan stdout out abort done
