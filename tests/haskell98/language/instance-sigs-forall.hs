{-# LANGUAGE InstanceSigs, ScopedTypeVariables, MultiParamTypeClasses, FlexibleInstances #-}
newtype Tree a = Tree [a] deriving Show

class C p f where
  build :: p a -> [a] -> f a

instance C Maybe Tree where
  build :: forall a. Maybe a -> [a] -> Tree a
  build _ xs = t
    where
      t :: Tree a
      t = Tree xs

class D f where
  mk :: [a] -> f a
instance D Tree where
  mk :: forall b. [b] -> Tree b
  mk ys = r where
    r :: Tree b
    r = Tree (reverse ys)

main :: IO ()
main = print (build (Just 'x') "ab" :: Tree Char, mk "cd" :: Tree Char)
