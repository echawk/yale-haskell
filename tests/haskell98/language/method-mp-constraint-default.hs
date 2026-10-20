{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FlexibleContexts #-}
module Main (main) where
class Monad m => Gen g m where
  word :: g -> m Int
data G = G
instance Gen G IO where
  word _ = return 7
class Unif a where
  unifM :: Gen g m => g -> m a
  other :: a -> Int
  unifM g = do { n <- word g; return (mk n) }
  mk :: Int -> a
instance Unif Int where
  other _ = 1
  mk n = n + 100
main :: IO ()
main = do
  x <- unifM G :: IO Int
  print x
