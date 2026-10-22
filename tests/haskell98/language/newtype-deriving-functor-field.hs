{-# LANGUAGE GeneralizedNewtypeDeriving, DeriveFunctor #-}
module Main (main) where
newtype Pointwise a = Pointwise { pointwise :: a } deriving (Eq, Show, Functor)
newtype Wrap a = Wrap (Maybe a) deriving (Show, Functor)
main :: IO ()
main = print (fmap (+ 1) (Pointwise (1 :: Int)), fmap not (Wrap (Just True)))
