{-# LANGUAGE TypeFamilies, ConstraintKinds, FlexibleContexts, UndecidableSuperClasses, TypeOperators, ScopedTypeVariables, RankNTypes, TypeApplications, AllowAmbiguousTypes #-}
module Main where
import Data.Coerce
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
instance Subst a => Subst [a] where
  type SubstArg [a] = SubstArg a
  applySubst rho = map (applySubst rho)
appT :: forall t . (Coercible t Term, EndoSubst t) => [t] -> t -> t
appT rho x = subT x
 where
   sub :: forall a b . (Coercible b a, SubstWith t a) => b -> b
   sub y = coerce (applySubst rho (coerce y :: a))
   subT :: t -> t
   subT = sub @t
main = print (appT [Var 7] (App (Var 0) (Var 1)))
