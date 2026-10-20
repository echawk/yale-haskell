{-# LANGUAGE TypeFamilies, StandaloneDeriving, DeriveDataTypeable #-}
module Main (main) where
import Data.Typeable
data family Vec a
newtype instance Vec Int = VInt [Int]
deriving instance Typeable Vec
data Plain a = Plain a
deriving instance Typeable Plain
main :: IO ()
main = print (typeOf (Plain 'x'))
