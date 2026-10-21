{-# LANGUAGE TypeFamilies, DataKinds, PolyKinds, TypeOperators, ConstraintKinds, KindSignatures, FlexibleContexts, ScopedTypeVariables, FlexibleInstances, MultiParamTypeClasses, UndecidableInstances #-}
-- Constraint families as dictionaries (Agda's KILLRANGE): a method's
-- All Bump (Domains t), its equality IsBase t ~ b deciding the instance

-- Agda's KILLRANGE: a constraint family's given parts
module Main (main) where
import Data.Kind (Constraint, Type)

type family All (p :: k -> Constraint) (as :: [k]) :: Constraint where
  All p '[]       = ()
  All p (a ': as) = (p a, All p as)

type family If (b :: Bool) (l :: k) (r :: k) :: k where
  If 'True  l r = l
  If 'False l r = r

type family IsBase (t :: Type) :: Bool where
  IsBase (a -> t) = 'False
  IsBase a        = 'True

type family Domains (t :: Type) :: [Type] where
  Domains t = If (IsBase t) '[] (Domains' t)
type family Domains' (t :: Type) :: [Type] where
  Domains' (a -> t) = a ': Domains t

class Bump a where
  bump :: a -> a
instance Bump Int where
  bump = (+ 1)
instance Bump Bool where
  bump = not

class BUMP t b where
  bumpN :: IsBase t ~ b => All Bump (Domains t) => t -> t

instance IsBase t ~ 'True => BUMP t 'True where
  bumpN v = v

instance BUMP t (IsBase t) => BUMP (a -> t) 'False where
  bumpN f a = bumpN (f (bump a))

pair :: Int -> Bool -> (Int, Bool)
pair = bumpN (,)

main :: IO ()
main = print (pair 1 True)
