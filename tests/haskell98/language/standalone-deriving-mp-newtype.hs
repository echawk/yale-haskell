{-# LANGUAGE StandaloneDeriving, GeneralizedNewtypeDeriving, MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, UndecidableInstances #-}
module Main (main) where

class Functor t => Indexed i t | t -> i where
  imap :: (i -> a -> b) -> t a -> t b
  ilist :: t a -> [(i, a)]

instance Indexed Int [] where
  imap f xs = zipWith f [0 ..] xs
  ilist xs = zip [0 ..] xs

newtype Wrap f a = Wrap (f a) deriving Show
instance Functor f => Functor (Wrap f) where
  fmap g (Wrap x) = Wrap (fmap g x)

deriving instance Indexed i f => Indexed i (Wrap f)

main :: IO ()
main = do
  print (imap (\i c -> (i, c)) (Wrap "ab"))
  print (ilist (Wrap [True, False]))
