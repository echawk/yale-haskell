{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, FlexibleContexts, UndecidableInstances #-}
class Fold full item | full -> item where
  foldr' :: (item -> b -> b) -> b -> full -> b
class Box v where unbox :: v a -> [a]
newtype L a = L [a]
instance Box L where unbox (L xs) = xs
instance Box v => Fold (v a) a where
  foldr' f z = foldr f z . unbox
main :: IO ()
main = print (foldr' (+) 0 (L [1, 2, 3 :: Int]))
