-- An Ord instance that defines only compare (the H98 minimal complete
-- definition alternative to (<=)).
module Main where
import Dialogue (stdout, appendChan, done, abort)

data Version = Version Int Int deriving Eq

instance Ord Version where
  compare (Version a b) (Version c d) = compare (a, b) (c, d)

main = appendChan stdout (unlines [
  show (Version 1 2 < Version 1 10, Version 2 0 <= Version 1 9),
  show (compare (Version 3 1) (Version 3 1), max (Version 0 1) (Version 0 2) == Version 0 2)
  ]) abort done
