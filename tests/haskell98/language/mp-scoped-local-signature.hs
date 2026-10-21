{-# LANGUAGE ScopedTypeVariables, MultiParamTypeClasses, FlexibleInstances, FlexibleContexts, TypeOperators #-}
module Main (main) where

data Args e a = Args (a -> e)
data (f :*: g) p = f p :*: g p
newtype K p = K Int

class R e ps f where
  r :: Args e a -> f a -> ps

instance R e [Int] K where
  r _ (K n) = [n]

instance (Monoid ps, R e ps f, R e ps g) => R e ps (f :*: g) where
  r (targs :: Args e p) (a :*: b) = pairsOf a `mappend` pairsOf b
    where
      pairsOf :: (R e ps h) => h p -> ps
      pairsOf = r targs

main :: IO ()
main = print (r (Args (\x -> ())) (K 1 :*: K (2 :: Int)) :: [Int])
