-- Records: a newtype with a field, a polymorphic function-valued field,
-- update in a where clause, and an operator field name (shown in parens).
module Main where

newtype Wrap = Wrap { unwrap :: Int } deriving (Show, Eq)

data Fn a = Fn { apply :: a -> a, fname :: String }

data Op = Op { (+++) :: Int } deriving Show

bump :: Fn Int -> Fn Int
bump f = f { fname = n ++ "'" }
  where n = fname f

main = do
  print (Wrap 3, unwrap (Wrap 4), (Wrap 5) { unwrap = 6 })
  let f = bump (Fn { apply = (+1), fname = "inc" })
  print (apply f 41, fname f)
  print (Op 2)
