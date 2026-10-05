-- Names that Haskell 1.2 exported from the Prelude but Haskell 98 does
-- not (they live in List, Array, Ratio, Complex, Numeric) can be
-- defined by a program without hiding anything.
module Main where

nub :: [Int] -> [Int]
nub (x:y:xs) | x == y = nub (y:xs)
nub (x:xs) = x : nub xs
nub [] = []

partition :: Int -> [a] -> [[a]]
partition n [] = []
partition n xs = take n xs : partition n (drop n xs)

transpose, sums :: [Int] -> Int
transpose = sum
sums = product

(!) :: [a] -> Int -> a
xs ! n = xs !! n

elems, indices :: [a] -> Int
elems = length
indices = length

genericLength :: [a] -> Integer
genericLength = fromIntegral . length

zip4 :: [a] -> [b] -> [(a, b)]
zip4 = zip

magnitude, numerator :: Int -> Int
magnitude = abs
numerator = negate

showInt :: Int -> String
showInt n = "#" ++ show n

main = appendChan stdout (unlines [
  show (nub [1, 1, 2, 2, 2, 3, 1]),
  show (partition 2 "abcde"),
  show (transpose [1, 2, 3], sums [1, 2, 3], "xyz" ! 1, elems "ab", indices [()]),
  show (genericLength "four", zip4 "ab" [True, False], magnitude (-4), numerator 4),
  showInt 9
  ]) abort done
