{-# LANGUAGE StandaloneDeriving, TypeFamilies, FlexibleContexts, UndecidableSuperClasses, UndecidableInstances #-}
module Main where
class DeBruijn a where deBruijnVar :: Int -> a
class DeBruijn (SubstArg a) => Subst a where
  type SubstArg a
  applySubst :: [SubstArg a] -> a -> a
data Term = Var Int | App Term Term deriving (Show, Eq, Ord)
instance DeBruijn Term where deBruijnVar = Var
instance Subst Term where
  type SubstArg Term = Term
  applySubst s (Var i) = if i < length s then s !! i else deBruijnVar i
  applySubst s (App a b) = App (applySubst s a) (applySubst s b)
data Abs a = Abs a deriving Show
instance (Subst a, Ord a) => Eq (Abs a) where
  Abs x == Abs y = compare x y == EQ
instance (Subst a, Ord a) => Ord (Abs a) where
  compare (Abs x) (Abs y) = compare (applySubst [] x) y
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
instance (Subst a, Ord a) => Eq (Tele a) where
  x == y = compare x y == EQ
instance (Subst a, Ord a) => Ord (Tele a) where
  compare EmptyTel EmptyTel = EQ
  compare EmptyTel _ = LT
  compare _ EmptyTel = GT
  compare (ExtendTel a x) (ExtendTel b y) = compare (a, x) (b, y)
lt :: (Subst a, Ord a) => Tele a -> Tele a -> Bool
lt x y = let inner p q = compare (Abs p) (Abs q) == LT in inner x y
main = print (lt (ExtendTel (Var 1) (Abs EmptyTel)) EmptyTel) >> print (compare (ExtendTel (Var 1) (Abs EmptyTel)) (ExtendTel (Var 1) (Abs EmptyTel))) >> print (applySubst [Var 9] (ExtendTel (Var 0) (Abs (ExtendTel (App (Var 0) (Var 1)) (Abs EmptyTel)))))
