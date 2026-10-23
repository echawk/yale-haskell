{-# LANGUAGE RankNTypes, ConstraintKinds, ScopedTypeVariables, InstanceSigs #-}
module Main where

type RecFn m a = Applicative m => (Int -> m Int) -> a -> m a
type RecRecFn m = forall a. Like a => a -> m a

class Like a where
  rf :: RecFn m a

instance Like Int where
  rf f x = f x

data P = A Int | B Int Int

instance Like P where
  rf :: forall m. RecFn m P
  rf f p =
    case p of
      A x -> A <$> rec x
      B f y -> B f <$> rec y
    where
      rec :: RecRecFn m
      rec e = rf f e

main :: IO ()
main = do
  r <- rf (\x -> return (x+1)) (B 1 2)
  case r of B a b -> print (a, b)
