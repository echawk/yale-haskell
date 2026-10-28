-- A GADT clause's family application reduced at its refinement only where
-- the clause's result meets the signature (Hoopl's arbGraph exit: Fact x f
-- is f in one clause, FactBase f in the other).
{-# LANGUAGE GADTs, TypeFamilies, ScopedTypeVariables #-}
data O
data C
data MaybeO ex t where
  JustO :: t -> MaybeO O t
  NothingO :: MaybeO C t
newtype LabelMap v = LM [v] deriving Show
type FactBase f = LabelMap f
type family Fact x f
type instance Fact C f = FactBase f
type instance Fact O f = f

run :: forall x f. Show f => MaybeO x Int -> Fact x f -> Maybe (Fact C f)
run m fact = exit m fact
  where
    exit :: MaybeO x Int -> Fact x f -> Maybe (Fact C f)
    exit (JustO n) f = Just (LM [f])
    exit NothingO f = Just f

main = print (run (JustO 1) 'a', run NothingO (LM "bc"))
