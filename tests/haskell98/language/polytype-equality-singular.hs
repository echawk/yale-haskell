-- lens' singular: conjoined's argument is given p ~ (->), and inside it
-- ins needs Biz (->) w where the other argument's pins has Biz p w: the
-- functional dependency's improvement between the two holds by the
-- equality, p not bound to (->).
{-# LANGUAGE RankNTypes, TypeFamilies, GADTs, FlexibleContexts, FunctionalDependencies, FlexibleInstances #-}
module Main where

class Conj p where
  conjoined :: ((p ~ (->)) => q (a -> b) r) -> q (p a b) r -> q (p a b) r
  arr :: (a -> b) -> p a b

instance Conj (->) where
  conjoined l _ = l
  arr = id

newtype Baz p a = Baz [a]

class Conj p => Sellable p w | w -> p where
  sell :: p a (w a)
instance Conj p => Sellable p (Baz p) where
  sell = arr (\a -> Baz [a])

class Biz p w | w -> p where
  pins :: w a -> [a]
instance Biz p (Baz p) where
  pins (Baz xs) = xs

ins :: Biz (->) w => w a -> [a]
ins = pins

type Over p f s a = p a (f a) -> s -> f s
type Traversing p s a = p a (Baz p a) -> s -> Baz p a

singular :: (Conj p, Functor f) => Traversing p s a -> Over p f s a
singular l = conjoined
  (\afb s -> let b = l sell s in case ins b of
      (w:_) -> fmap (const s) (afb w)
      []    -> error "empty")
  (\pafb s -> let b = l sell s in case pins b of
      _ -> error "indexed")

trav :: Traversing (->) (Int, Int) Int
trav f (x, y) = f x

main = print (singular trav (\x -> Just (x + 1)) (1, 2))
