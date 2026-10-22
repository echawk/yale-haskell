{-# LANGUAGE TypeFamilies, ConstraintKinds, FlexibleContexts, UndecidableSuperClasses, TypeOperators #-}
module Main where
class DeBruijn a where deBruijnVar :: Int -> a
class DeBruijn (SubstArg a) => Subst a where
  type SubstArg a
  applySubst :: [SubstArg a] -> a -> a
type SubstWith t a = (Subst a, SubstArg a ~ t)
type EndoSubst a = SubstWith a a
data Term = Var Int | App Term Term deriving Show
instance DeBruijn Term where deBruijnVar = Var
instance Subst Term where
  type SubstArg Term = Term
  applySubst s (Var i) = if i < length s then s !! i else Var i
  applySubst s (App a b) = App (applySubst s a) (applySubst s b)
lookupS :: EndoSubst a => [a] -> Int -> a
lookupS rho i = if i >= length rho then deBruijnVar i else applySubst rho (rho !! i)
lookupT :: (Subst a, SubstArg a ~ a) => [a] -> Int -> a
lookupT rho i = if i >= length rho then deBruijnVar i else applySubst rho (rho !! i)
main = do
  print (lookupS [App (Var 1) (Var 0), Var 7] 0)
  print (lookupS [Var 3] 5 :: Term)
  print (lookupT [Var 3] 0 :: Term)
