-- A newtype deriving, through another module's newtype, a class whose
-- superclasses it also derives, listed after it (JHC's Properties: Collection,
-- SetLike, then Semigroup, Monoid): their dictionaries are the field type's.
{-# LANGUAGE GeneralizedNewtypeDeriving, TypeFamilies #-}
module Main where
import GndChainBits

newtype Props = Props (BS Bool) deriving (Show, Collection, SetLike, Semigroup, Monoid)
type instance Elem Props = Bool
type instance Key Props = Bool

main = print (toList (fromList [True] <> (mempty :: Props)), member True (fromList [True] :: Props))
