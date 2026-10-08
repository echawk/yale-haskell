-- A context on a data declaration (Haskell 98 section 4.2.1):
-- constructing or matching the type requires the constraint.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data (Eq a) => Set a = Set [a]

empty :: (Eq a) => Set a
empty = Set []

insert :: (Eq a) => a -> Set a -> Set a
insert x s@(Set xs) | x `elem` xs = s
                    | otherwise   = Set (x : xs)

size :: (Eq a) => Set a -> Int
size (Set xs) = length xs

out :: String
out = unlines [ show (size (foldr insert empty "mississippi"))
              , show (size (foldr insert empty [1, 2, 1, 3, 2 :: Int])) ]

main = appendChan stdout out abort done
