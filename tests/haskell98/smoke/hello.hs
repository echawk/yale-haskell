module Main where
import Dialogue (stdout, appendChan, done, abort)

primes :: [Int]
primes = sieve [2..] where sieve (p:xs) = p : sieve [x | x <- xs, x `mod` p /= 0]

data Tree a = Leaf | Node (Tree a) a (Tree a) deriving Show

insert :: Ord a => a -> Tree a -> Tree a
insert x Leaf = Node Leaf x Leaf
insert x t@(Node l y r) | x < y = Node (insert x l) y r
                        | x > y = Node l y (insert x r)
                        | otherwise = t

main = appendChan stdout (unlines [ "Hello from Yale Haskell!"
                                  , show (take 15 primes)
                                  , show (foldr insert Leaf [3,1,4,1,5,9,2,6 :: Int])
                                  , show (product [1..25 :: Integer])
                                  , show (sqrt 2 :: Double, 7 / 2 :: Float) ]) abort done
