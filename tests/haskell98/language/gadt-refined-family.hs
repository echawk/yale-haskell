-- A type family application at a GADT-refined index reduces in the clause
-- (Hoopl's project Closed: Fact x f is FactBase f where x is C).
{-# LANGUAGE GADTs, TypeFamilies, RankNTypes, ScopedTypeVariables #-}
data O
data C

data Shape x where
  Closed :: Shape C
  Open   :: Shape O

class IsMap map where
  mapMap :: (a -> b) -> map a -> map b

newtype LabelMap v = LM [(Int, v)] deriving Show
instance IsMap LabelMap where
  mapMap f (LM xs) = LM [(k, f v) | (k, v) <- xs]

type family Fact x f
type FactBase f = LabelMap f
type instance Fact C f = FactBase f
type instance Fact O f = f

project :: forall x a. Shape x -> Fact x (a, a) -> Fact x a
project Open = \pair -> fst pair
project Closed = \pair -> mapMap fst pair

main :: IO ()
main = do
  print (project Open (1 :: Int, 2))
  print (project Closed (LM [(1, ("a", "b"))]))
