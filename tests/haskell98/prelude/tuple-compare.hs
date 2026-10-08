-- compare on tuples of several arities, exercising the tuple Ord
-- dictionary whose `compare' method is present in H98 (Ord declares it).
-- The runtime builds the dictionary from the class definition; this
-- locks in that `compare' is included as the last Ord method.
module Main where
import Dialogue (stdout, appendChan, done, abort)

out :: String
out = unlines
  [ show (compare (1 :: Int, 'a') (1 :: Int, 'b'))          -- LT on 2-tuple
  , show (compare (1 :: Int, 'b') (1 :: Int, 'a'))          -- GT on 2-tuple
  , show (compare (1,2,3 :: Int) (1,2,2 :: Int))            -- GT on 3-tuple
  , show (compare (1,2,2 :: Int) (1,2,3 :: Int))            -- LT on 3-tuple
  , show (compare ('x', 5 :: Int, True, "q") ('x', 5 :: Int, True, "q"))  -- EQ on 4-tuple
  , show [ (x, y) | x <- [1,2,3 :: Int], y <- [1,2,3 :: Int], x < y ]
  ]

main = appendChan stdout out abort done
