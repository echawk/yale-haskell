-- Ordering and compare: derived compare, matching on LT/EQ/GT, and an
-- Ord instance that defines only compare, used via <, max and a sort.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data Size = Small | Large deriving (Eq, Ord)

data Version = Version Int Int

instance Eq Version where
  a == b = compare a b == EQ

instance Ord Version where
  compare (Version a b) (Version c d) = case compare a c of
                                          EQ -> compare b d
                                          r  -> r

ordName :: Ordering -> String
ordName LT = "LT"
ordName EQ = "EQ"
ordName GT = "GT"

vname :: Version -> String
vname (Version a b) = show a ++ "." ++ show b

isort :: (Ord a) => [a] -> [a]
isort = foldr ins [] where
  ins x [] = [x]
  ins x (y:ys) = if x <= y then x : y : ys else y : ins x ys

out :: String
out = unlines [ unwords (map ordName [compare 1 2, compare 'b' 'b', compare Large Small])
              , show (Version 1 2 < Version 1 10, max (Version 2 0) (Version 1 9) == Version 2 0)
              , unwords (map vname (isort [Version 1 10, Version 0 9, Version 1 2])) ]

main = appendChan stdout out abort done
