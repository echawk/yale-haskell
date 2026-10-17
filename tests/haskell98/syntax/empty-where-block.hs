-- Haskell 98 layout (report 10.3): a where block whose first token is
-- not indented past the enclosing block is empty (async's instance
-- whose methods CPP removed).
class C a where
  m :: a -> Int
  m _ = 1

instance C Int where

f :: Int -> Int
f = (+ 1)

main = print (m (3 :: Int), f 1)
