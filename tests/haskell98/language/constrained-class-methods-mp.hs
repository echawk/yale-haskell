{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}
import Data.List (sort, nub)
class LL full item | full -> item where
  toL :: full -> [item]
  fromL :: [item] -> full
  sortL :: Ord item => full -> full
  sortL = fromL . sort . toL
  nubL :: Eq item => full -> full
  nubL = fromL . nub . toL

newtype Bag = Bag [Int] deriving Show
instance LL Bag Int where
  toL (Bag xs) = xs
  fromL = Bag
  nubL (Bag xs) = Bag (reverse (nub xs))

instance LL [a] a where
  toL = id
  fromL = id

main :: IO ()
main = print (sortL (Bag [3, 1, 2]), nubL (Bag [1, 1, 2]), sortL "cab", nubL "aab")
