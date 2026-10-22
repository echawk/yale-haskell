{-# LANGUAGE TypeFamilies, ConstraintKinds, FlexibleContexts, UndecidableSuperClasses, TypeOperators #-}
module Main where
class DeBruijn a where deBruijnVar :: Int -> a
class DeBruijn (SubstArg a) => Subst a where
  type SubstArg a
  applySubst :: [SubstArg a] -> a -> a
type EndoSubst a = (Subst a, SubstArg a ~ a)
data Term = Var Int | App Term Term deriving Show
instance DeBruijn Term where deBruijnVar = Var
instance Subst Term where
  type SubstArg Term = Term
  applySubst s (Var i) = if i < length s then s !! i else Var i
  applySubst s (App a b) = App (applySubst s a) (applySubst s b)
composeS :: EndoSubst a => [a] -> [a] -> [a]
composeS rho [] = rho
composeS rho (u : sgm) = applySubst rho u : composeS rho sgm
main = print (composeS [Var 7] [App (Var 0) (Var 1)])
