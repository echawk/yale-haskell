{-# LANGUAGE FlexibleContexts, FlexibleInstances, TypeOperators #-}
-- A constraint on an application (GEq (f p)) given through a subclass
-- (GOrd (f p)): the superclass dictionary of an instance's context
import GHC.Generics

class GEq a where
  geq :: a -> a -> Bool
class GEq a => GOrd a where
  gcompare :: a -> a -> Ordering

instance Eq c => GEq (K1 i c p) where
  geq (K1 a) (K1 b) = a == b
instance Ord c => GOrd (K1 i c p) where
  gcompare (K1 a) (K1 b) = compare a b
instance (GEq (f p), GEq (g p)) => GEq ((f :*: g) p) where
  geq (a1 :*: b1) (a2 :*: b2) = geq a1 a2 && geq b1 b2
instance (GOrd (f p), GOrd (g p)) => GOrd ((f :*: g) p) where
  gcompare (a1 :*: b1) (a2 :*: b2) = gcompare a1 a2 <> gcompare b1 b2

main :: IO ()
main = do
  let x = K1 3 :*: K1 'a' :: (K1 R Int :*: K1 R Char) ()
  print (geq x x, gcompare x x)
