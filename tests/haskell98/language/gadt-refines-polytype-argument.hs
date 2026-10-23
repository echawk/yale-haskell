{-# LANGUAGE DataKinds, PolyKinds, GADTs, KindSignatures, RankNTypes, TypeOperators #-}
module Main where
import Data.Kind (Type)

data All :: (x -> Type) -> [x] -> Type where
  Nil  :: All p '[]
  Cons :: p x -> All p xs -> All p (x ': xs)

data Index :: [x] -> x -> Type where
  Zero :: Index (x ': xs) x
  Suc  :: Index xs x -> Index (y ': xs) x

forgetIndex :: Index xs x -> Int
forgetIndex Zero    = 0
forgetIndex (Suc i) = 1 + forgetIndex i

newtype K a x = K a

mapWithIndex :: (forall x. Index xs x -> p x -> q x) -> All p xs -> All q xs
mapWithIndex f Nil = Nil
mapWithIndex f (Cons p ps) = Cons (f Zero p) $ mapWithIndex (f . Suc) ps

forgetAll :: (forall x. b x -> a) -> All b xs -> [a]
forgetAll f Nil         = []
forgetAll f (Cons x xs) = f x : forgetAll f xs

main :: IO ()
main = do
  let xs = Cons (K 'a') (Cons (K 'b') Nil) :: All (K Char) '[Int, Bool]
      ys = mapWithIndex (\i (K c) -> K (c, forgetIndex i)) xs
  print (forgetAll (\(K p) -> p) ys)
