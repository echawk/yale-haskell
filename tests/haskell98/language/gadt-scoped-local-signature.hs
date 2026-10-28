-- A local signature of the enclosing binding's scoped variables only, its
-- clauses matching a GADT: their results are the signature's (Hoopl's
-- labelsDefined: exitLabel NothingO = setEmpty, a LabelSet).
{-# LANGUAGE GADTs, TypeFamilies, ScopedTypeVariables, RankNTypes #-}
data O
data C

data MaybeO ex t where
  JustO    :: t -> MaybeO O t
  NothingO ::      MaybeO C t

class IsSet set where
  type ElemOf set
  setEmpty :: set
  setSingleton :: ElemOf set -> set

newtype LabelSet = LabelSet [Int] deriving Show
instance IsSet LabelSet where
  type ElemOf LabelSet = Int
  setEmpty = LabelSet []
  setSingleton x = LabelSet [x]

exitLabel :: MaybeO x Int -> LabelSet
exitLabel NothingO  = setEmpty
exitLabel (JustO b) = setSingleton b

data G e x where
  GNil  :: G O O
  GMany :: MaybeO e Int -> G e x

labels :: forall e x. G e x -> LabelSet
labels GNil = setEmpty
labels (GMany x) = exitL x
  where exitL :: MaybeO e Int -> LabelSet
        exitL NothingO = setEmpty
        exitL (JustO b) = setSingleton b

main = print (labels (GMany (JustO 4)), labels GNil)
