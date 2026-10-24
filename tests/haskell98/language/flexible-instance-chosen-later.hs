-- A constraint at Pattern' t, t an enclosing binding's variable, waits
-- for t (two flexible instances; Agda's dotSub in LHS.Unify).
{-# LANGUAGE TypeFamilies, FlexibleInstances, FlexibleContexts, ConstraintKinds #-}
module Main where

data Pattern' x = VarP x | DotP Int deriving Show
data A = A deriving Show
data B = B deriving Show

class Subst a where
  type SubstArg a
  applySubst :: [a] -> a -> a

type SubstWith s a = (Subst a, SubstArg a ~ s)
type EndoSubst a = SubstWith a a

instance Subst (Pattern' A) where
  type SubstArg (Pattern' A) = Pattern' A
  applySubst _ p = p

instance Subst (Pattern' B) where
  type SubstArg (Pattern' B) = Pattern' B
  applySubst _ p = p

composeS :: EndoSubst a => [a] -> [a] -> [a]
composeS xs ys = map (applySubst xs) ys ++ xs

dotP :: Int -> Pattern' a
dotP = DotP

f :: [Int] -> Pattern' A -> Pattern' A
f bound p =
  let dotSub = foldr composeS [] [ [dotP i] | i <- bound ]
  in applySubst dotSub p

main :: IO ()
main = print (f [1,2] (VarP A))
