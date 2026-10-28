-- A synonym named as the promoted constructor it stands for (GHC's
-- type Branched = 'Branched): 'C is the promoted constructor.
{-# LANGUAGE DataKinds, KindSignatures, GADTs #-}
data BranchFlag = Branched | Unbranched
type Branched = 'Branched
type Unbranched = 'Unbranched

newtype Branches (br :: BranchFlag) = MkBranches [Int]

many :: [Int] -> Branches Branched
many = MkBranches

one :: Int -> Branches Unbranched
one x = MkBranches [x]

toBranched :: Branches br -> Branches Branched
toBranched (MkBranches xs) = MkBranches xs

data Nat = Z | S Nat
data Vec (n :: Nat) a where
  VNil :: Vec 'Z a
  VCons :: a -> Vec n a -> Vec ('S n) a

vlen :: Vec n a -> Int
vlen VNil = 0
vlen (VCons _ v) = 1 + vlen v

main :: IO ()
main = case (toBranched (one 3), many [1, 2]) of
  (MkBranches a, MkBranches b) -> print (a ++ b, vlen (VCons 'x' (VCons 'y' VNil)))
