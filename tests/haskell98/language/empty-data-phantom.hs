module Main where
data Void
data Phantom a
newtype Tag a = Tag Int deriving Show
absurd :: Void -> a
absurd v = case v of _ -> error "void"
x :: Phantom Int -> Int
x _ = 3
main = print (Tag 3 :: Tag Void) >> print (x undefined) >> print c
type Const a b = a
c :: Const Int Bool
c = 4
