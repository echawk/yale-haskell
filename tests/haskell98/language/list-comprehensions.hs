-- List comprehensions: several generators, dependent generators,
-- guards, nested comprehensions, and generators whose pattern can fail
-- (the element is skipped).
module Main where
import Dialogue (stdout, appendChan, done, abort)

pythag :: Int -> [(Int, Int, Int)]
pythag n = [(a, b, c) | c <- [1..n], b <- [1..c], a <- [1..b], a*a + b*b == c*c]

showTriple :: (Int, Int, Int) -> String
showTriple (a, b, c) = show a ++ "," ++ show b ++ "," ++ show c

singletons :: [[Int]] -> [Int]
singletons xss = [x | [x] <- xss]

evensAt :: [Bool] -> [Int]
evensAt bs = [i | (i, True) <- zip [0..] bs]

table :: Int -> [[Int]]
table n = [[i * j | j <- [1..n]] | i <- [1..n]]

out :: String
out = unlines
  ( map showTriple (pythag 20)
  ++ [ unwords (map show (singletons [[1], [2,3], [], [4]]))
     , unwords (map show (evensAt [True, False, True, True]))
     , unlines (map (unwords . map show) (table 3))
     , [c | c <- "Hello World", c /= 'o', c /= ' ']
     , show (length [() | x <- [1..10], y <- [x..10], odd (x + y)])
     ])

main = appendChan stdout out abort done
