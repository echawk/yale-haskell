{-# LANGUAGE DataKinds, KindSignatures, MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, TypeOperators #-}
module Main (main) where
import GHC.Generics
class IsRecord (f :: * -> *) r | f -> r where isRec :: f p -> r -> r
instance {-# OVERLAPPING #-} IsRecord (M1 S ('MetaSel 'Nothing u ss ds) f) Bool where isRec _ r = r
instance IsRecord (K1 i c) Bool where isRec _ r = not r
main :: IO ()
main = print (isRec (M1 (K1 'x') :: M1 S ('MetaSel 'Nothing 'NoSourceUnpackedness 'NoSourceStrictness 'DecidedLazy) (K1 R Char) ()) True)
