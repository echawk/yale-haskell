{-# LANGUAGE DataKinds, KindSignatures, MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}
module Main (main) where
data Meta = MetaSel (Maybe Bool) Bool
data Box (m :: Meta) = Box
class IsNamed m r | m -> r where named :: Box m -> r -> r
instance IsNamed ('MetaSel 'Nothing u) Bool where named _ r = r
main :: IO ()
main = print (named (Box :: Box ('MetaSel 'Nothing 'True)) False)
