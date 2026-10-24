-- Subst (Pattern' x), from the context of Subst [a], waits for x as the
-- constraint itself would (Agda's ceq in LHS.Unify).
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

instance Subst a => Subst [a] where
  type SubstArg [a] = SubstArg a
  applySubst _ xs = xs

consS :: a -> [a] -> [a]
consS = (:)

f :: [[Pattern' A]] -> [[Pattern' A]]
f rho1 =
  let ceq  = applySubst [] [dotP 3]
      rho3 = consS ceq rho1
  in rho3

main :: IO ()
main = print (f [[VarP A]])
