-- A type family equation on a data family's application (JHC's Key (GMap
-- Atom v) = Atom) reduces at the data instance's type.
{-# LANGUAGE TypeFamilies, FlexibleContexts #-}
module Main where
import qualified Data.Map as M

data family GMap k :: * -> *
newtype instance GMap Int v = GMapInt (M.Map Int v)

type family Key m
type instance Key (GMap Int v) = Int

class MapLike m where
  mkeys :: m -> [Key m]
instance MapLike (GMap Int v) where
  mkeys (GMapInt m) = M.keys m

newtype TyEnv = TyEnv (GMap Int String)

showKeys :: TyEnv -> String
showKeys (TyEnv m) = concatMap show (mkeys m)

main = putStrLn (showKeys (TyEnv (GMapInt (M.fromList [(1,"a"),(2,"b")]))))
