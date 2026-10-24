-- A local function generalized over Subst (Named (Pattern' x)), whose
-- instance's context reaches the undecided Subst (Pattern' x) (Agda's
-- hcompD' in Coverage.Cubical).
{-# LANGUAGE RankNTypes, TypeFamilies, FlexibleInstances, FlexibleContexts, GADTs #-}
module Main where

data Pattern' x = VarP x | DotP Int | DefP String [Named (Pattern' x)] deriving Show
newtype Named a = Named a deriving Show
instance Subst a => Subst (Named a) where applySubst s (Named a) = Named (applySubst s a)
instance DeBruijn a => DeBruijn (Named a) where deBruijnVar = Named . deBruijnVar
data DBPatVar = DBPatVar Int deriving Show
data SplitPatVar = SplitPatVar deriving Show

class DeBruijn a where deBruijnVar :: Int -> a
class Subst a where applySubst :: [Int] -> a -> a

instance DeBruijn (Pattern' DBPatVar) where deBruijnVar = VarP . DBPatVar
instance DeBruijn (Pattern' SplitPatVar) where deBruijnVar _ = VarP SplitPatVar
instance Subst (Pattern' DBPatVar) where applySubst _ p = p
instance Subst (Pattern' SplitPatVar) where applySubst _ p = p

type Vars = forall b. (Subst b, DeBruijn b) => [Maybe b]

bindN :: [String] -> (Vars -> Maybe a) -> Maybe a
bindN ns f = f [ Just (deBruijnVar i) | (i, _) <- zip [0..] ns ]

patternToTerm :: Pattern' DBPatVar -> String
patternToTerm = show

build :: String -> Maybe String
build q = do
  let hcompD' n = bindN ["psi", "u"] $ \ x0 -> do
        x0 <- sequence x0
        pure $ DefP q (Named (DotP n) : x0)
  fmap patternToTerm (hcompD' 1)

main :: IO ()
main = print (build "hcomp")
