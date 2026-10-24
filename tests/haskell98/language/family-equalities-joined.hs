-- t ~ AbsOfRef (t, Elim) and AbsOfRef (t, Elim) ~ Expr, both undecided,
-- give t ~ Expr (Agda's foldM (curry toAbstract) f elims).
{-# LANGUAGE TypeFamilies, FlexibleInstances #-}
module Main where

import Control.Monad (foldM)

data Expr = V String | App Expr String deriving Show
data Elim = Apply String deriving Show
type Elims = [Elim]

class ToAbstract r where
  type AbsOfRef r
  toAbstract :: r -> IO (AbsOfRef r)

instance ToAbstract (Expr, Elim) where
  type AbsOfRef (Expr, Elim) = Expr
  toAbstract (f, Apply a) = return (App f a)

instance ToAbstract (Expr, Elims) where
  type AbsOfRef (Expr, Elims) = Expr
  toAbstract (f, elims) = foldM (curry toAbstract) f elims

instance ToAbstract (Maybe Int, String) where
  type AbsOfRef (Maybe Int, String) = String
  toAbstract (_, s) = return s

main :: IO ()
main = toAbstract (V "f", [Apply "x", Apply "y"]) >>= print
