-- An instance at a type variable applied to any types (FlexibleInstances):
-- Hoopl's instance NonLocal n => LabelsPtr (n e C).
{-# LANGUAGE GADTs, FlexibleInstances #-}
data O
data C

class NonLocal n where
  successors :: n e C -> [Int]

data Node e x where
  Jump :: Int -> Node O C
  Mid  :: Node O O

instance NonLocal Node where
  successors (Jump l) = [l]

data Block n e x where
  BlockOC :: n O C -> Block n O C

instance NonLocal n => NonLocal (Block n) where
  successors (BlockOC n) = successors n

class LabelsPtr l where
  targetLabels :: l -> [Int]

instance NonLocal n => LabelsPtr (n e C) where
  targetLabels n = successors n

instance LabelsPtr Int where
  targetLabels l = [l]

instance LabelsPtr l => LabelsPtr [l] where
  targetLabels = concatMap targetLabels

-- at a type variable applied (Hoopl's postorder_dfs at block n O C)
viaBlock :: NonLocal (block n) => block n O C -> [Int]
viaBlock b = targetLabels b

main :: IO ()
main = do
  print (targetLabels (Jump 3))
  print (targetLabels (BlockOC (Jump 4)))
  print (targetLabels [1, 2 :: Int])
  print (viaBlock (BlockOC (Jump 5)))
