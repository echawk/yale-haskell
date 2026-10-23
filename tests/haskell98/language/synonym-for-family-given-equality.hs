{-# LANGUAGE DataKinds, TypeFamilies, MultiParamTypeClasses, FlexibleInstances,
             FlexibleContexts, UndecidableInstances, ScopedTypeVariables, TypeOperators,
             PolyKinds, KindSignatures #-}
module Main where
import Data.Proxy
import Data.Kind (Type)

type family If (b :: Bool) (x :: k) (y :: k) :: k where
  If 'True x y = x
  If 'False x y = y

type family IsBase (t :: Type) :: Bool where
  IsBase (a -> t) = 'False
  IsBase a        = 'True

type family Domains (t :: Type) :: [Type] where
  Domains t = If (IsBase t) '[] (Domains' t)
type family Domains' (t :: Type) :: [Type] where
  Domains' (a -> t) = a ': Domains t

type family Foldr (c :: k -> l -> l) (n :: l) (as :: [k]) :: l where
  Foldr c n '[]       = n
  Foldr c n (a ': as) = c a (Foldr c n as)

data Function :: Type -> Type -> Type
type family Apply (t :: Function k l -> Type) (u :: k) :: l

type family Foldr' (c :: Function k (Function l l -> Type) -> Type)
                   (n :: l) (as :: [k]) :: l where
  Foldr' c n '[]       = n
  Foldr' c n (a ': as) = Apply (Apply c a) (Foldr' c n as)

type family Map (f :: Function k l -> Type) (as :: [k]) :: [l] where
  Map f as = Foldr' (ConsMap0 f) '[] as

data ConsMap0 :: (Function k l -> Type) -> Function k (Function [l] [l] -> Type) -> Type
data ConsMap1 :: (Function k l -> Type) -> k -> Function [l] [l] -> Type
type instance Apply (ConsMap0 f)    a = ConsMap1 f a
type instance Apply (ConsMap1 f a) tl = Apply f a ': tl

data Constant1 :: Type -> Function k Type -> Type
type instance Apply (Constant1 a) b = a

type family Constant (b :: Type) (as :: [k]) :: [Type] where
  Constant b as = Map (Constant1 b) as

data StrictPair a b = Pair a b deriving Show
type StrictProducts (as :: [Type]) = Foldr StrictPair () as

class VALU t b where
  args :: b ~ IsBase t => Proxy t -> [Int] -> Maybe (StrictProducts (Constant Int (Domains t)))

instance VALU t 'True where
  args _ xs = case xs of
    [] -> Just ()
    _  -> Nothing

instance VALU t (IsBase t) => VALU (a -> t) 'False where
  args _ xs = case xs of
    x : xs' -> Pair x <$> args (Proxy :: Proxy t) xs'
    _       -> Nothing

main :: IO ()
main = do
  print (args (Proxy :: Proxy Bool) [])
  print (args (Proxy :: Proxy (Char -> Char -> Bool)) [1,2])
