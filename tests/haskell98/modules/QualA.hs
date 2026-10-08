module QualA (T(..), size, (<+>), shared) where

infixl 6 <+>

data T = Leaf | Node T Int T deriving Show

size :: T -> Int
size Leaf = 0
size (Node l _ r) = size l + 1 + size r

(<+>) :: Int -> Int -> Int
a <+> b = a * 10 + b

shared :: String
shared = "from QualA"
