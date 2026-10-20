{-# LANGUAGE TypeApplications, ScopedTypeVariables, MultiParamTypeClasses, FlexibleInstances, AllowAmbiguousTypes #-}
module Main (main) where
import Data.Coerce

class Len v a where
  len :: v a -> Int

newtype Wrap a = Wrap [a]
instance Len [] a where
  len = length
instance Len Wrap a where
  len = coerce (len @[] @a)

main :: IO ()
main = print (len (Wrap "abcd"), len @Maybe' @Int `seq` 0)
  where _ = ()

data Maybe' a = N
instance Len Maybe' a where
  len _ = 0
