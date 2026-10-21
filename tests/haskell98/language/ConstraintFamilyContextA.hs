{-# LANGUAGE TypeFamilies, DataKinds, PolyKinds, TypeOperators, ConstraintKinds, KindSignatures #-}
module ConstraintFamilyContextA (All) where
import Data.Kind (Constraint)

type family All (p :: k -> Constraint) (as :: [k]) :: Constraint where
  All p '[]       = ()
  All p (a ': as) = (p a, All p as)
