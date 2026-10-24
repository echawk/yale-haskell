-- An instance context recursion 60 deep (one per constructor field, as
-- Agda's icodeN' PragmaOptions) is not taken for a loop.
{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FlexibleContexts, TypeFamilies, DataKinds, UndecidableInstances, ScopedTypeVariables #-}
module Main where
import Data.Proxy

type family IsBase t :: Bool where
  IsBase (a -> t) = 'False
  IsBase t = 'True

class Count t b where
  count :: Proxy t -> Proxy b -> Int

instance Count t 'True where count _ _ = 0
instance Count t (IsBase t) => Count (a -> t) 'False where
  count _ _ = 1 + count (Proxy :: Proxy t) (Proxy :: Proxy (IsBase t))

data Big = Big Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int

countOf :: forall t. Count t (IsBase t) => t -> Int
countOf _ = count (Proxy :: Proxy t) (Proxy :: Proxy (IsBase t))

main :: IO ()
main = print (countOf Big)

