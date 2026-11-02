{-# LANGUAGE GADTs, TypeOperators #-}
-- a GADT constructor in one argument refines another's type: (x,y) at a,
-- Pair's result (a,b) :-> c (QuickCheck's Test.QuickCheck.Function)
data a :-> c where
  Pair :: (a :-> (b :-> c)) -> ((a,b) :-> c)
  (:+:) :: (a :-> c) -> (b :-> c) -> (Either a b :-> c)
  Unit :: c -> (() :-> c)
  Nil  :: a :-> c

instance Functor ((:->) a) where
  fmap f (Pair p) = Pair (fmap (fmap f) p)
  fmap f (p :+: q) = fmap f p :+: fmap f q
  fmap f (Unit c) = Unit (f c)
  fmap _ Nil = Nil

abstract :: (a :-> c) -> c -> (a -> c)
abstract (Pair p) d (x,y) = abstract (fmap (\q -> abstract q d y) p) d x
abstract (p :+: q) d exy = either (abstract p d) (abstract q d) exy
abstract (Unit c) _ _ = c
abstract Nil d _ = d

f1 :: ((), Either () ()) :-> Char
f1 = Pair (Unit (Unit 'l' :+: Nil))

main :: IO ()
main = do
  putStrLn [abstract f1 'd' ((), Left ()), abstract f1 'd' ((), Right ())]
  putStrLn [abstract (Nil :: Int :-> Char) 'n' 3]
