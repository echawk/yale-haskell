-- A clause with a GADT pattern guard: its tuple argument's variables have
-- the signature's types in its where (GHC's CmmContFlowOpt maybe_concat).
{-# LANGUAGE GADTs, TypeFamilies #-}
import qualified Data.Map as M
data O
data C
data Node e x where
  Branch :: Int -> Node O C
  Mid :: Node O O

class IsMap map where
  type KeyOf map
  mapLookup :: KeyOf map -> map a -> Maybe a
newtype LabelMap v = LM (M.Map Int v)
instance IsMap LabelMap where
  type KeyOf LabelMap = Int
  mapLookup k (LM m) = M.lookup k m

step :: Node O C -> (Int, LabelMap Int) -> (Int, LabelMap Int)
step last (n, backEdges)
  | Branch b <- last, hasOnePredecessor b = (n + 1, backEdges)
  | otherwise = (n, backEdges)
  where
    numPreds bid = maybe 0 id (mapLookup bid backEdges)
    hasOnePredecessor b = numPreds b == 1

main = print (fst (step (Branch 1) (0, LM (M.fromList [(1, 1)]))))
