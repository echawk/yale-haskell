-- A section of an operator with a polytype argument, its operand a
-- composition: (^. l1 . l2), Agda's.
{-# LANGUAGE RankNTypes #-}
module Main where

import Data.Functor.Const

type Lens' o i = forall f. Functor f => (i -> f i) -> o -> f o

infixl 8 ^.
(^.) :: o -> Lens' o i -> i
o ^. l = getConst $ l Const o

data S = S { _inner :: T }
data T = T { _val :: Int }

inner :: Lens' S T
inner f (S t) = fmap S (f t)

val :: Lens' T Int
val f (T v) = fmap T (f v)

main :: IO ()
main = do
  let s = S (T 7)
  print (s ^. inner . val)
  print ((^. inner . val) s)
  print (fmap (^. inner . val) [s])
