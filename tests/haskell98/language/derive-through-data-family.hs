-- Deriving (newtype and stock) for a type whose field is a data family's
-- application (JHC's newtype TyEnv = TyEnv (GMap Atom TyTy) deriving Monoid).
{-# LANGUAGE TypeFamilies, GeneralizedNewtypeDeriving #-}
module Main where
import qualified Data.Map as M

data family GMap k :: * -> *
newtype instance GMap Int v = GMapInt (M.Map Int v) deriving (Show, Semigroup, Monoid)

newtype TyEnv = TyEnv (GMap Int String) deriving (Show, Semigroup, Monoid)

main = print (TyEnv (GMapInt (M.fromList [(1,"a")])) <> mempty)
