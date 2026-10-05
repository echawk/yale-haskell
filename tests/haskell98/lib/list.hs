-- The List library.
module Main where

import List

main = appendChan stdout (unlines [
  show (elemIndex 3 [1, 2, 3, 3 :: Int], elemIndices 'a' "banana", find even [1, 3, 4, 5 :: Int]),
  show (findIndex (> 2) [1, 2, 3 :: Int], findIndices odd [1, 2, 3, 5 :: Int]),
  show (nub [3, 1, 3, 2, 1 :: Int], nubBy (\a b -> a `mod` 3 == b `mod` 3) [1 .. 7 :: Int]),
  show (delete 'a' "banana", "abcabc" \\ "ca", union "abc" "bcd", intersect [1, 2, 3, 4] [2, 4, 6 :: Int]),
  show (intersperse ',' "abc", transpose ["abc", "de", "f"], partition even [1 .. 8 :: Int]),
  show (group "Mississippi", groupBy (\a b -> a <= b) [1, 2, 2, 3, 1, 2, 0, 4, 5, 2 :: Int]),
  show (inits "abc", tails "abc", isPrefixOf "ab" "abc", isSuffixOf "bc" "abc", isPrefixOf "b" "abc"),
  show (mapAccumL (\a x -> (a + x, a * x)) 0 [1, 2, 3 :: Int], mapAccumR (\a x -> (a + x, a * x)) 0 [1, 2, 3 :: Int]),
  show (unfoldr (\n -> if n > 60 then Nothing else Just (n, n * 2)) (1 :: Int)),
  show (sort [3, 1, 4, 1, 5, 9, 2, 6 :: Int], sortBy (\a b -> compare b a) "hello", insert 4 [1, 3, 5, 7 :: Int]),
  show (maximumBy (\a b -> compare (snd a) (snd b)) [(1, 'z'), (2, 'a') :: (Int, Char)], minimumBy (\a b -> compare (abs a) (abs b)) [-3, 2, -1 :: Int]),
  show (genericLength "abcd" :: Integer, genericTake (2 :: Integer) "abc", genericDrop (1 :: Integer) "abc"),
  show (genericSplitAt (1 :: Integer) "ab", genericIndex "abc" (2 :: Integer), genericReplicate (3 :: Integer) 'x'),
  show (zip4 [1 :: Int, 2] "ab" [True, False] [(), ()], zipWith5 (\a b c d e -> a + b + c + d + e) [1] [2] [3] [4] [5 :: Int]),
  show (unzip4 [(1 :: Int, 'a', True, "x"), (2, 'b', False, "y")]),
  show (zip7 [1 :: Int] [2 :: Int] [3 :: Int] [4 :: Int] [5 :: Int] [6 :: Int] [7 :: Int], deleteFirstsBy (==) [1, 2, 3, 2 :: Int] [2])
  ]) abort done
