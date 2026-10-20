{-# LANGUAGE DerivingStrategies, StandaloneDeriving, GeneralizedNewtypeDeriving, DeriveAnyClass #-}
module Main (main) where
newtype Key = Key String
deriving newtype instance Eq Key
deriving newtype instance Ord Key
deriving stock instance Show Key
data Color = Red | Green
deriving stock instance Eq Color
deriving instance Show Color
main :: IO ()
main = print (Key "a" < Key "b", Key "x" == Key "x", Key "k", Red == Green, Green)
