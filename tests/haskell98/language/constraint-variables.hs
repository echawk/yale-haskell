{-# LANGUAGE ConstraintKinds, DataKinds, KindSignatures, PolyKinds, RankNTypes, TypeOperators, GADTs #-}
{-# LANGUAGE FlexibleInstances, FlexibleContexts, MultiParamTypeClasses, UndecidableInstances, ScopedTypeVariables #-}
-- ConstraintKinds' constraint variables: c y with c a class parameter
import Data.Kind (Type, Constraint)
import Data.Proxy

data NP (f :: k -> Type) (xs :: [k]) where
  Nil  :: NP f '[]
  (:*) :: f x -> NP f xs -> NP f (x ': xs)
infixr 5 :*

newtype I a = I a

class All (c :: k -> Constraint) (xs :: [k]) where
  cfoldr :: proxy c -> (forall y. c y => f y -> r -> r) -> r -> NP f xs -> r
instance All c '[] where
  cfoldr _ _ z Nil = z
instance (c x, All c xs) => All c (x ': xs) where
  cfoldr p f z (x :* xs) = f x (cfoldr p f z xs)

showAll :: All Show xs => NP I xs -> [String]
showAll = cfoldr (Proxy :: Proxy Show) (\(I y) acc -> show y : acc) []

-- a constraint variable in a function's own signature
withC :: c a => Proxy c -> (forall b. c b => b -> r) -> a -> r
withC _ k x = k x

main :: IO ()
main = do
  print (showAll (I (1 :: Int) :* I True :* I "x" :* Nil))
  putStrLn (withC (Proxy :: Proxy Show) show (42 :: Int))
