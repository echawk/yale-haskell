{-# LANGUAGE TypeFamilies, FlexibleContexts #-}
import qualified Data.Set as Set
type family Element mono
type instance Element [a] = a

class SetContainer set where
  union :: set -> set -> set
  empty' :: set
  -- an equality with the class's variable on one side
  unions :: (Element mono ~ set) => [mono] -> set
  unions = foldr (\m acc -> acc) empty'
  unionAll :: (Element mono ~ set, mono ~ [set]) => mono -> set
  unionAll = foldr union empty'

instance Ord a => SetContainer (Set.Set a) where
  union = Set.union
  empty' = Set.empty

main :: IO ()
main = print (Set.toList (unionAll [Set.fromList [3, 1], Set.fromList [2, 3 :: Int]]))
