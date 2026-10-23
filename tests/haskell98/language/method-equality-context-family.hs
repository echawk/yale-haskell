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

type family Len (as :: [Type]) :: Type where
  Len '[] = ()
  Len (a ': as) = (Int, Len as)

class VALU t b where
  args :: b ~ IsBase t => Proxy t -> [Int] -> Maybe (Len (Domains t))

instance VALU t 'True where
  args _ xs = case xs of
    [] -> Just ()
    _  -> Nothing

instance VALU t (IsBase t) => VALU (a -> t) 'False where
  args _ xs = case xs of
    x : xs' -> (\r -> (x, r)) <$> args (Proxy :: Proxy t) xs'
    _       -> Nothing

main :: IO ()
main = do
  print (args (Proxy :: Proxy Bool) [])
  print (args (Proxy :: Proxy (Char -> Char -> Bool)) [1,2])
