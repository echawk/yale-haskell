{-# LANGUAGE FlexibleContexts #-}
module Main where

newtype TCMT m a = TCM { unTCM :: Int -> m a }
type TCM = TCMT IO

instance Functor m => Functor (TCMT m) where
  fmap f (TCM g) = TCM (fmap f . g)
instance Applicative m => Applicative (TCMT m) where
  pure x = TCM (const (pure x))
  TCM f <*> TCM x = TCM (\n -> f n <*> x n)
instance Monad m => Monad (TCMT m) where
  TCM m >>= k = TCM (\n -> m n >>= \a -> unTCM (k a) n)

class Monad m => MonadC m where
  addC :: Int -> m Int
instance MonadC (TCMT IO) where
  addC k = TCM (\n -> return (n + k))

useC :: MonadC TCM => Int -> TCM Int
useC k = addC k >>= addC

main :: IO ()
main = unTCM (useC 1) 10 >>= print
