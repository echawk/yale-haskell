{-# LANGUAGE GeneralizedNewtypeDeriving, DeriveFoldable #-}
module Main where
import Prelude hiding (null)
import NewtypeSharedA
newtype Favorites a = Favorites { toList :: [a] }
  deriving (Foldable, Show, Null)
x :: Favorites Int
x = empty
main = print x
