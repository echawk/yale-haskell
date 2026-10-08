-- Names that the Haskell 1.2 Prelude exports but the Haskell 98
-- Prelude does not are free for programs to define.
module Main where
import Dialogue (stdout, appendChan, done, abort)

type Assoc k v = [(k, v)]

data Bin = Zero | One

showInt :: Int -> String
showInt n = '#' : show n

copy :: Int -> a -> [a]
copy n x = take n (repeat x)

binDigit :: Bin -> Char
binDigit Zero = '0'
binDigit One  = '1'

table :: Assoc Int Char
table = [(1, 'a')]

out :: String
out = unlines [ showInt 7, map binDigit [One, Zero, One]
              , copy 3 'x', show (length table) ]

main = appendChan stdout out abort done
