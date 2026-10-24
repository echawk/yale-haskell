-- The monomorphism restriction keeps x of a pending Subst (Pattern' x)
-- monomorphic, for a later binding to fix (Agda's ceq in LHS.Unify).
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

consS :: a -> [a] -> [a]
consS = (:)

f :: [Pattern' A] -> Pattern' A -> [Pattern' A]
f rho1 p =
  let ceq  = applySubst [] (dotP 3)
      rho3 = consS ceq rho1
  in rho3

g :: [Pattern' A] -> IO [Pattern' A]
g rho1 = do
  let ceq  = applySubst [] (dotP 4)
      rho3 = consS ceq rho1
  return rho3

main :: IO ()
main = print (f [VarP A] (VarP A)) >> g [] >>= print
