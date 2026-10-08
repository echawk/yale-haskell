-- do notation outside IO, in the list monad: a failed pattern match in
-- a binding calls fail, which for lists is [] (Haskell 98 section 3.14).
module Main where
import Dialogue (stdout, appendChan, done, abort)

pairs :: [(Int, Char)]
pairs = do
  x <- [1, 2, 3]
  c <- "ab"
  return (x, c)

heads :: [Int]
heads = do
  (x : _) <- [[1, 2], [], [3], []]
  return x

pythag :: [(Int, Int, Int)]
pythag = do
  c <- [1 .. 15]
  b <- [1 .. c]
  a <- [1 .. b]
  if a * a + b * b == c * c then return (a, b, c) else []

showPair :: (Int, Char) -> String
showPair (x, c) = show x ++ [c]

out :: String
out = unlines [ unwords (map showPair pairs)
              , unwords (map show heads)
              , unwords [show a ++ "," ++ show b ++ "," ++ show c | (a, b, c) <- pythag] ]

main = appendChan stdout out abort done
