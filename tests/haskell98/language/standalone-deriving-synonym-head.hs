{-# LANGUAGE StandaloneDeriving, FlexibleInstances #-}
module Main where
data Term = Var Int | Lit Int deriving (Eq, Ord, Show)
data Level' t = Max Integer [PlusLevel' t] deriving Show
data PlusLevel' t = Plus Integer t deriving Show
type Level = Level' Term
type PlusLevel = PlusLevel' Term
deriving instance Eq Level
deriving instance Ord Level
deriving instance Eq PlusLevel
instance Ord PlusLevel where
  compare (Plus a x) (Plus b y) = compare (a, x) (b, y)
main = print (Max 1 [Plus 2 (Var 1)] < Max 1 [Plus 2 (Var 3)], compare (Plus 1 (Lit 0)) (Plus 1 (Var 9)))
