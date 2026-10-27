-- recursion-schemes' shape: Base, a type family applied past its arity;
-- methods with their own constraint on the class's variable
-- (hoist :: Recursive t => .. in class Corecursive t) and rank-n
-- arguments (prepro); lambek = cata (fmap embed), whose embed is decided
-- by its signature's Base t t through the deferred family equalities.
{-# LANGUAGE TypeFamilies, RankNTypes #-}
module Main where

type family Base t :: * -> *

class Functor (Base t) => Recursive t where
  project :: t -> Base t t
  cata :: (Base t a -> a) -> t -> a
  cata f = c where c = f . fmap c . project
  para2 :: Corecursive t => (Base t (t, a) -> a) -> t -> a
  para2 f = zyg embed f
  prepro :: Corecursive t => (forall b. Base t b -> Base t b) -> (Base t a -> a) -> t -> a
  prepro e f = c where c = f . fmap (c . hoist e) . project

class Functor (Base t) => Corecursive t where
  embed :: Base t t -> t
  hoist :: Recursive t => (forall a. Base t a -> Base t a) -> t -> t
  hoist n = cata (embed . n)

data ListF e r = NilF | ConsF e r
instance Functor (ListF e) where
  fmap _ NilF = NilF
  fmap f (ConsF e r) = ConsF e (f r)
type instance Base [a] = ListF a
instance Recursive [a] where
  project [] = NilF
  project (x:xs) = ConsF x xs
instance Corecursive [a] where
  embed NilF = []
  embed (ConsF x xs) = x:xs

zyg :: Recursive t => (Base t b -> b) -> (Base t (b, a) -> a) -> t -> a
zyg g f = snd . cata (\x -> (g (fmap fst x), f x))

lambek :: (Recursive t, Corecursive t) => (t -> Base t t)
lambek = cata (fmap embed)

dbl :: ListF Int r -> ListF Int r
dbl NilF = NilF
dbl (ConsF x r) = ConsF (2*x) r

main = print (embed (lambek [7,8::Int]) :: [Int]) >> print (hoist dbl [1,2,3::Int]) >> print (prepro dbl (\l -> case l of NilF -> 0; ConsF x n -> x + n) [1,2,3::Int]) >> print (para2 (\l -> case l of NilF -> 0; ConsF x (xs, n) -> x + n + length xs) [1,2,3::Int]) >> print (cata (\l -> case l of NilF -> 0; ConsF x n -> x + n) [1,2,3::Int])
