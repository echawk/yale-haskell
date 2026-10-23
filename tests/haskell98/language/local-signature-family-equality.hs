{-# LANGUAGE TypeFamilies, ScopedTypeVariables, RankNTypes, FlexibleContexts, UndecidableSuperClasses, UndecidableInstances #-}
module Main where
class DeBruijn a where deBruijnVar :: Int -> a
class DeBruijn (SubstArg a) => Subst a where
  type SubstArg a
  applySubst :: [SubstArg a] -> a -> a
data Term = Var Int | App Term Term deriving Show
instance DeBruijn Term where deBruijnVar = Var
instance Subst Term where
  type SubstArg Term = Term
  applySubst s (Var i) = if i < length s then s !! i else deBruijnVar i
  applySubst s (App a b) = App (applySubst s a) (applySubst s b)
data Abs a = Abs a deriving Show
instance Subst a => Subst (Abs a) where
  type SubstArg (Abs a) = SubstArg a
  applySubst rho (Abs a) = Abs (applySubst (deBruijnVar 0 : rho) a)
instance (Subst a, Subst b, SubstArg a ~ SubstArg b) => Subst (a, b) where
  type SubstArg (a, b) = SubstArg a
  applySubst rho (x, y) = (applySubst rho x, applySubst rho y)
data Tele a = EmptyTel | ExtendTel a (Abs (Tele a)) deriving Show
instance Subst a => Subst (Tele a) where
  type SubstArg (Tele a) = SubstArg a
  applySubst rho EmptyTel = EmptyTel
  applySubst rho (ExtendTel t tel) = uncurry ExtendTel (applySubst rho (t, tel))
data Pair = Pair Term (Tele Term) deriving Show
substPair :: [Term] -> Pair -> Pair
substPair rho (Pair t tel) = Pair (rf t) (rf tel)
  where
    rf :: forall a . (Subst a, SubstArg a ~ Term) => a -> a
    rf x = applySubst rho x
main = print (substPair [Var 5] (Pair (Var 0) EmptyTel)) >> print (applySubst [Var 9] (ExtendTel (Var 0) (Abs (ExtendTel (App (Var 0) (Var 1)) (Abs EmptyTel)))))
