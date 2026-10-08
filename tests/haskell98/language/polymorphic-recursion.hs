-- Polymorphic recursion is allowed when the function has a type
-- signature (Haskell 98 section 4.4.1): depth calls itself at type
-- Nested [a].
module Main where
import Dialogue (stdout, appendChan, done, abort)

data Nested a = Flat a | Nest (Nested [a])

depth :: Nested a -> Int
depth (Flat _) = 0
depth (Nest n) = 1 + depth n

total :: Nested Int -> Int
total n = go n (\x -> x)
  where
    go :: Nested b -> (b -> Int) -> Int
    go (Flat x) k = k x
    go (Nest m) k = go m (sum . map k)

out :: String
out = unlines [ show (depth (Nest (Nest (Flat [[1 :: Int]]))))
              , show (total (Nest (Nest (Flat [[1, 2], [3]])))) ]

main = appendChan stdout out abort done
