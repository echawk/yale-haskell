-- A polymorphic argument's one-parameter constraint gives its class's
-- flexible superclass: Subst b gives DeBruijn (SubstArg b) (Agda's bind').
{-# LANGUAGE RankNTypes, TypeFamilies, FlexibleContexts, UndecidableSuperClasses #-}
module Main where

class DeBruijn a where deBruijnVar :: Int -> a

class DeBruijn (SubstArg a) => Subst a where
  type SubstArg a
  applySubst :: [SubstArg a] -> a -> a

data Term = Var Int | Lam Term deriving Show
instance DeBruijn Term where deBruijnVar = Var
instance Subst Term where
  type SubstArg Term = Term
  applySubst s (Var i) = if i < length s then s !! i else Var i
  applySubst s (Lam t) = Lam (applySubst (deBruijnVar 0 : s) t)

newtype NamesT m a = NamesT { unName :: [String] -> m a }

inCxt :: (Monad m, Subst a) => [String] -> a -> NamesT m a
inCxt cxt a = NamesT $ \cxt' -> return (applySubst (replicate (length cxt' - length cxt) (deBruijnVar 0)) a)

bind' :: Monad m => String -> ((forall b. (Subst b, DeBruijn b) => NamesT m b) -> NamesT m a) -> NamesT m a
bind' n f = NamesT $ \cxt -> unName (f (inCxt (n:cxt) (deBruijnVar 0))) (n:cxt)

main :: IO ()
main = unName (bind' "x" (\v -> NamesT (\c -> do { t <- unName v c; return (Lam t) }))) [] >>= print
