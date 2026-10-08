-- The Ordering type, compare, and the H98 max/min defaults.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data T = A | B | C deriving (Eq, Ord)

data P = P Int Int deriving (Eq, Ord)

newOrd :: Int -> Int -> Ordering
newOrd x y = compare (x `mod` 3) (y `mod` 3)

main = appendChan stdout (unlines [
  show [compare 1 (2::Int), compare 'b' 'b', compare 3.5 (1.0::Double)],
  show (compare (1,'a') (1,'b'), compare [1,2] [1::Int], compare "abc" "abd"),
  show (compare A C, compare (P 1 2) (P 1 1), compare (Just B) Nothing),
  show (map (newOrd 4) [0, 1, 2]),
  show ([LT ..], [minBound .. maxBound :: Ordering], succ LT, pred GT),
  show (LT < GT, maximum [EQ, GT, LT], fromEnum GT, toEnum 1 :: Ordering),
  show (read "GT" :: Ordering, max 'a' 'z', min 2.5 (1.5 :: Double)),
  show (max (P 1 1) (P 0 9) == P 1 1, min "pear" "apple")
  ]) abort done
