{-# LANGUAGE TypeOperators #-}
import GHC.Generics
main = do
  print (sum (Par1 3 :*: Par1 (4 :: Int)), fmap (\x -> case x of L1 (Par1 n) -> n; R1 U1 -> 0) (traverse Just (L1 (Par1 1) :: (Par1 :+: U1) Int)))
  print (map unPar1 (unComp1 (fmap (+1) (Comp1 [Par1 (1::Int)]))), unPar1 (Par1 (5 :: Int)))
