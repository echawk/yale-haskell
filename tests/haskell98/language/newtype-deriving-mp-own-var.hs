{-# LANGUAGE GeneralizedNewtypeDeriving, DeriveFoldable, MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}
module Main where
class Null a where
  empty :: a
  null :: a -> Bool
instance Null [a] where
  empty = []
  null = Prelude.null
class Singleton el coll | coll -> el where
  singleton :: el -> coll
instance Singleton a [a] where singleton x = [x]
newtype Favorites a = Favorites { toList :: [a] }
  deriving (Foldable, Show, Null, Singleton a)
main = print (empty :: Favorites Int) >> print (singleton 'c' :: Favorites Char) >> print (sum (Favorites [1,2,3]))
