{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}
module Main (main) where
data LPair a = LPair a a deriving Show
data SPair a = SPair !a !a deriving Show
newtype Wrap a = Wrap a deriving Show
newtype SWrap a = SWrap a deriving Show
class Strict lazy strict | lazy -> strict, strict -> lazy where
  toStrict :: lazy -> strict
  toLazy :: strict -> lazy
instance Strict (Wrap a) (SWrap a) where
  toStrict (Wrap a) = SWrap a
  toLazy (SWrap a) = Wrap a
instance Strict (LPair a) (SPair a) where
  toStrict (LPair a b) = SPair a b
  toLazy (SPair a b) = LPair a b
main :: IO ()
main = do
  print (toStrict (LPair 1 (2 :: Int)))
  print (toLazy (SPair 'a' 'b'))
  print (fmap toStrict (Just (LPair True False)) :: Maybe (SPair Bool))
