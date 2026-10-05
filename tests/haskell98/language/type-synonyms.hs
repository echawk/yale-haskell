-- Type synonyms, with and without parameters, nested in each other.
module Main where

type Name     = String
type Pair a   = (a, a)
type Table k v = [(k, v)]
type Phonebook = Table Name Int

swapPair :: Pair a -> Pair a
swapPair (x, y) = (y, x)

find :: (Eq k) => k -> Table k v -> [v]
find k xs = [v | (k', v) <- xs, k == k']

book :: Phonebook
book = [("alice", 1234), ("bob", 5678), ("alice", 4321)]

out :: String
out = unlines [ show (swapPair (1 :: Int, 2))
              , unwords (map show (find "alice" book))
              , show (length (find "carol" book)) ]

main = appendChan stdout out abort done
