module Main where

data Tree = Leaf | Node Tree Int Int Tree

insert :: Int -> Int -> Tree -> Tree
insert k v Leaf = Node Leaf k v Leaf
insert k v (Node l k' v' r)
  | k < k' = Node (insert k v l) k' v' r
  | k > k' = Node l k' v' (insert k v r)
  | otherwise = Node l k v r

lookupT :: Int -> Tree -> Maybe Int
lookupT _ Leaf = Nothing
lookupT k (Node l k' v r)
  | k < k' = lookupT k l
  | k > k' = lookupT k r
  | otherwise = Just v

size :: Tree -> Int
size Leaf = 0
size (Node l _ _ r) = size l + 1 + size r

depth :: Tree -> Int
depth Leaf = 0
depth (Node l _ _ r) = 1 + max (depth l) (depth r)

keys :: Int -> [Int]
keys n = take n (iterate (\x -> (x * 1103515245 + 12345) `mod` 2147483648) 42)

main :: IO ()
main = do
  let ks = keys 200000
      t = foldr (\k acc -> insert (k `mod` 500000) k acc) Leaf ks
      hits = length [() | k <- [0, 3 .. 500000], Just _ <- [lookupT k t]]
  print (size t)
  print (depth t)
  print hits
