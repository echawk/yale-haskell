{-# LANGUAGE DataKinds, GADTs, KindSignatures, TypeFamilies #-}
-- DataKinds' type-level lists: '[], '[a], [a, b], t ': ts.
import Data.Kind (Type)

data HList (ts :: [Type]) where
  HNil  :: HList '[]
  HCons :: t -> HList ts -> HList (t ': ts)

type family Head (ts :: [Type]) :: Type where
  Head (t ': ts) = t

type family Len (ts :: [Type]) :: Type where
  Len '[] = ()
  Len (t : ts) = Maybe (Len ts)

hhead :: HList (t ': ts) -> t
hhead (HCons x _) = x

single :: HList '[Bool]
single = HCons True HNil

pair :: HList [Int, Char]
pair = HCons 1 (HCons 'x' HNil)

firstOf :: HList ts -> Head ts -> Head ts
firstOf _ x = x

len3 :: Len '[Int, Int, Int]
len3 = Just (Just (Just ()))

main :: IO ()
main = do
  print (hhead single)
  print (hhead pair + 1)
  print (firstOf pair 41 + 1)
  print len3
