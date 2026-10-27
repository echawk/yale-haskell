-- A GADT constructor rebuilt in a clause that matched it, its result
-- refining the indices by a repeated variable (lens' Magma :: i -> a ->
-- Magma i b b a, under the newtype Molten): typed apart and related to
-- its use part by part, the local equality t ~ b not needed.
{-# LANGUAGE GADTs #-}
module Main where

data Magma i t b a where
  MagmaAp   :: Magma i (x -> y) b a -> Magma i x b a -> Magma i y b a
  MagmaPure :: x -> Magma i x b a
  Magma     :: i -> a -> Magma i b b a

newtype Molten i a b t = Molten (Magma i t b a)

count :: Magma i t b a -> Int
count (Magma _ _) = 1
count (MagmaPure _) = 0
count (MagmaAp x y) = count x + count y

countM :: Molten i a b t -> Int
countM (Molten (Magma _ _)) = 1
countM (Molten (MagmaPure _)) = 0
countM (Molten (MagmaAp x y)) = countM (Molten x) + countM (Molten y)

main = print (count (MagmaAp (MagmaPure id) (Magma 'i' 'a') :: Magma Char Int Int Char), countM (Molten (MagmaAp (MagmaPure id) (Magma 'i' 'a')) :: Molten Char Char Int Int))

ex :: Molten i a b t -> Maybe t
ex (Molten (Magma _ _)) = Nothing
ex (Molten (MagmaPure x)) = Just x
ex (Molten (MagmaAp x y)) = ex (Molten x) <*> ex (Molten y)

re :: (Molten i a b t -> r) -> Molten i a b t -> [r]
re k (Molten (Magma i a)) = [k (Molten (Magma i a))]
re k (Molten (MagmaPure x)) = [k (Molten (MagmaPure x))]
re k (Molten (MagmaAp x y)) = []

class IC w where
  iext :: (w b c t -> r) -> w a c t -> w a b r

instance IC (Molten i) where
  iext k (Molten (Magma i a)) = Molten (MagmaPure (k (Molten (Magma i a))))
  iext k (Molten (MagmaPure x)) = Molten (MagmaPure (k (Molten (MagmaPure x))))
