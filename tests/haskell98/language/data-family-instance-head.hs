{-# LANGUAGE TypeFamilies, FlexibleContexts #-}
module Main (main) where

class Elt a where
  wrap :: [a] -> Vec a
  elems :: Vec a -> [a]

data family Vec a
newtype instance Vec Int = VInt [Int]
data instance Vec Bool = VBool Int [Bool]

instance Elt Int where
  wrap = VInt
  elems (VInt xs) = xs
instance Elt Bool where
  wrap bs = VBool (length bs) bs
  elems (VBool _ bs) = bs

-- instances on the family itself
instance (Show a, Elt a) => Show (Vec a) where
  show v = "Vec " ++ show (elems v)

class Sized f where
  size :: f a -> Int
instance Sized Vec where
  size _ = 7

main :: IO ()
main = do
  print (wrap [1, 2, 3 :: Int])
  print (wrap [True])
  print (size (wrap [False]), size (VInt []))
