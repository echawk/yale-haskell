-- H98 list functions: Int-typed take/drop/splitAt/!!, and the
-- additions concatMap, replicate, lookup.
module Main where
import Dialogue (stdout, appendChan, done, abort)

main = appendChan stdout (unlines [
  show (take 3 "haskell", drop 4 "haskell", splitAt 2 [1, 2, 3 :: Int]),
  show (take (-1) "abc", drop (-1) "abc", splitAt (-2) "ab", take 10 "ab"),
  show ("abcdef" !! 4, [10, 20, 30 :: Int] !! 0),
  show (concatMap show [1, 22, 333 :: Int], concatMap (replicate 2) "abc"),
  show (replicate 3 True, replicate 0 'x', length (replicate 5 ())),
  show (lookup 3 [(1, "one"), (3, "three")], lookup 9 [(1, "one")]),
  show (zip3 "ab" [1, 2 :: Int] [True, False], unzip3 [(1 :: Int, 'a', "x")]),
  show (zipWith3 (\a b c -> a + b * c) [1, 2] [3, 4] [5, 6 :: Int]),
  show (words "  hello  world \n", unwords ["a", "b"], lines "x\ny\n", unlines ["p", "q"]),
  show (scanl (+) 0 [1, 2, 3 :: Int], scanr (+) 0 [1, 2, 3 :: Int], scanl1 max [3, 1, 4 :: Int], scanr1 (+) [1, 2, 3 :: Int]),
  show (takeWhile (< 3) ([1 ..] :: [Int]), dropWhile (< 3) [1 .. 5 :: Int], span even [2, 4, 5, 6 :: Int], break (== ' ') "ab cd"),
  show (elem 3 [1, 2, 3 :: Int], notElem 'z' "abc", and [], or [], any odd [2, 4 :: Int], all odd [1, 3 :: Int]),
  show (sum [1 .. 100 :: Integer], product [1 .. 10 :: Int], maximum "hello", minimum [3, 1, 2 :: Int]),
  show (iterate (* 2) 1 !! 10 :: Int, take 4 (cycle [1, 2 :: Int]), take 2 (repeat 'z')),
  show (reverse [1, 2, 3 :: Int], null [], init "abc", last "abc", foldr1 (-) [10, 3, 2 :: Int], foldl1 (-) [10, 3, 2 :: Int])
  ]) abort done
