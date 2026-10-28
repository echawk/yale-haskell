{-# LANGUAGE GeneralizedNewtypeDeriving, TypeFamilies, FlexibleContexts #-}
module GndChainBits where

type family Elem s
type family Key s
class Monoid s => Collection s where
  fromList :: [Elem s] -> s
  toList :: s -> [Elem s]
class Collection s => SetLike s where
  member :: Key s -> s -> Bool

newtype Bits = Bits [Int] deriving (Show, Semigroup, Monoid)
newtype BS a = BS Bits deriving (Show, Semigroup, Monoid)
type instance Elem (BS a) = a
type instance Key (BS a) = Elem (BS a)
instance Enum a => Collection (BS a) where
  fromList = BS . Bits . map fromEnum
  toList (BS (Bits xs)) = map toEnum xs
instance Enum a => SetLike (BS a) where
  member k (BS (Bits xs)) = fromEnum k `elem` xs
