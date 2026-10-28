-- A local binding's class constraint on a type containing a family
-- application (Eq [(KeyOf map, a)]: GHC's equalBlockMaps) is a flexible one.
{-# LANGUAGE TypeFamilies, FlexibleContexts #-}
import qualified Data.Map as M

class IsMap map where
  type KeyOf map
  mapToList :: map a -> [(KeyOf map, a)]

newtype LabelMap v = LM (M.Map Int v)
instance IsMap LabelMap where
  type KeyOf LabelMap = Int
  mapToList (LM m) = M.toList m

same :: LabelMap [Int] -> LabelMap [Int] -> Bool
same x y = go x y
  where
    go :: LabelMap [Int] -> LabelMap [Int] -> Bool
    go a b = equalBlockMaps a b
    equalBlockMaps a b
        = a' == b'
      where a' = map f $ mapToList a
            b' = map f $ mapToList b
            f (key, elt) = (key, elt)

main = print (same (LM (M.fromList [(1, [2])])) (LM (M.fromList [(1, [2])])))
