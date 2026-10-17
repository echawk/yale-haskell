{-# LANGUAGE GHC2024, NoMonoLocalBinds #-}
-- A language standard in a LANGUAGE pragma stands for its extensions
-- (here LambdaCase and DataKinds from GHC2024); NoE turns one off.
import Data.Kind (Type)

data HList (ts :: [Type]) where
  HNil :: HList '[]
  HCons :: t -> HList ts -> HList (t ': ts)

hlength :: HList ts -> Int
hlength = \case
  HNil -> 0
  HCons _ xs -> 1 + hlength xs

main :: IO ()
main = print (hlength (HCons 'a' (HCons True HNil)))
