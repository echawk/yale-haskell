{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FlexibleContexts #-}
module Main (main) where

class Monad m => Gen g m where
  word :: g -> m Int

data G = G
instance Gen G IO where
  word _ = return 7

class Unif a where
  unifM :: Gen g m => g -> m a

instance Unif Int where
  unifM g = word g

instance Unif Bool where
  unifM g = do { n <- word g; return (odd n) }

main :: IO ()
main = do
  x <- unifM G :: IO Int
  y <- unifM G :: IO Bool
  print (x, y)
