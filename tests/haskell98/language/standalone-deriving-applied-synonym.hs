{-# LANGUAGE StandaloneDeriving, FlexibleInstances #-}
module Main where
data Term = Var Int | Lit Int deriving (Eq, Ord, Show)
data Dom' t e = Dom t e deriving Show
type Dom = Dom' Term
deriving instance Eq a => Eq (Dom a)
deriving instance Ord a => Ord (Dom a)
main = print (Dom (Var 1) 'a' < Dom (Var 1) 'b', compare (Dom (Lit 0) True) (Dom (Var 3) False))
