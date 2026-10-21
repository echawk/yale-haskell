{-# LANGUAGE DataKinds, TypeFamilies, TypeOperators, UndecidableInstances, FlexibleContexts, KindSignatures #-}
import GHC.TypeLits

type family Check (b :: Bool) :: Bool where
  Check 'True = 'True
  Check 'False = TypeError ('Text "no: " ':<>: 'ShowType Int ':$$: 'Text "end")

class Ok (b :: Bool)
instance Ok 'True

f :: Ok (Check 'True) => Int
f = 3

main :: IO ()
main = print (f :: Int)
