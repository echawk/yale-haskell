-- A GADT clause's result against a signature's type synonym (FactBase f,
-- LabelMap f): the synonym expanded, not applied as map a's map (Hoopl).
{-# LANGUAGE GADTs, TypeFamilies, ScopedTypeVariables, RankNTypes #-}
data O
data C

data MaybeO ex t where
  JustO    :: t -> MaybeO O t
  NothingO ::      MaybeO C t

class IsMap map where
  type KeyOf map
  mapEmpty :: map a
  mapSingleton :: KeyOf map -> a -> map a

newtype LabelMap v = LM [(Int, v)] deriving Show
instance IsMap LabelMap where
  type KeyOf LabelMap = Int
  mapEmpty = LM []
  mapSingleton k v = LM [(k, v)]

type FactBase f = LabelMap f

data G e x where
  GNil  :: G O O
  GMany :: MaybeO e (Int, f) -> G e x

facts :: forall e x f. MaybeO x (Int, f) -> FactBase f
facts m = exitFacts m
  where exitFacts :: MaybeO x (Int, f) -> FactBase f
        exitFacts NothingO = mapEmpty
        exitFacts (JustO (k, f)) = mapSingleton k f

main = print (facts (JustO (1, "a")), facts (NothingO :: MaybeO C (Int, Bool)))
