{-# LANGUAGE FlexibleInstances, UndecidableInstances #-}
-- An instance at a variable application, C (t a) (Agda's TermSize
-- (t a)): used where no other instance is
module Main (main) where

class Size a where
  size :: a -> Int
  -- a default using the instance at its own type (C (t a) at t a)
  sizes :: a -> [Int]
  sizes x = [size x]

instance Size Int where
  size _ = 1

instance Size Bool where
  size _ = 1

instance {-# OVERLAPPABLE #-} (Foldable t, Size a) => Size (t a) where
  size = sum . map size . foldr (:) []

main :: IO ()
main = print (size [1, 2, 3 :: Int], size (Just True), size [[True, False], [True]], sizes [True])
