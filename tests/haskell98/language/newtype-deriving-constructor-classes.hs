{-# LANGUAGE GeneralizedNewtypeDeriving #-}
-- Newtype deriving of classes of type constructors (Bifunctor (Biap bi)),
-- and derived Functor with a flexible context (Functor (bi a))
import Data.Bifunctor
import Data.Bifoldable
newtype Biap bi a b = Biap { getBiap :: bi a b } deriving (Eq, Show, Bifunctor, Bifoldable, Functor)
newtype W f a = W (f a) deriving (Show, Functor, Foldable)
main :: IO ()
main = do
  print (bimap (+1) show (Biap (1, 2)), bifoldMap show show (Biap (Left 3 :: Either Int Char)))
  print (fmap (*2) (Biap (1, 5)), fmap not (W [True]), sum (W (Just 4)))
