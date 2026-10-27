-- A lambda's list pattern for an argument whose type is a constrained
-- polytype (Agda's \ [phi,u0] -> .. at Vars m = forall b. (Subst b,
-- DeBruijn b) => [NamesT m b]): matched on its instance.
{-# LANGUAGE RankNTypes #-}
module Main where

type Vars = forall b. Num b => [b]

bindN :: Int -> (Vars -> r) -> r
bindN n f = f (map fromIntegral [1..n])

main = do
  print (bindN 2 (\ [a, b] -> (a + b :: Int, a * 10)))
  print (bindN 3 (\ xs -> sum xs :: Integer))
