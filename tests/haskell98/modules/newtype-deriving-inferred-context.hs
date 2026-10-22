{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Main where
import NewtypeViaContextA
data Aug c = Aug c Int deriving Show
instance PartialOrd (Aug c) where leq (Aug _ a) (Aug _ b) = a <= b
newtype CMSet c = CMSet (Favorites (Aug c)) deriving (Show, Semigroup, Monoid)
union :: CMSet c -> CMSet c -> CMSet c
union = mappend
main = print (union (CMSet (Favorites [Aug 'a' 1])) mempty)
