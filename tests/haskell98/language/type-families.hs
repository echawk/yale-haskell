-- TypeFamilies: open and closed type families, associated types and
-- data families.
{-# LANGUAGE TypeFamilies, DataKinds, GADTs, KindSignatures, FlexibleContexts #-}
import qualified Data.Map as M

-- open family with instances
type family Elem c
type instance Elem [e] = e
type instance Elem (M.Map k v) = v

class Container c where
  empty :: c
  insert :: Elem c -> c -> c
  toL :: c -> [Elem c]

instance Container [a] where
  empty = []
  insert = (:)
  toL = id

-- closed family: equations tried in order
type family Swap a where
  Swap Int = Bool
  Swap Bool = Int
  Swap a = a

swapInt :: Int -> Swap Int
swapInt n = n > 0

swapChar :: Char -> Swap Char
swapChar c = succ c

-- associated type synonym
class Collects c where
  type Item c
  cinsert :: Item c -> c -> c
  clist :: c -> [Item c]

newtype IntBag = IntBag [Int]

instance Collects IntBag where
  type Item IntBag = Int
  cinsert x (IntBag xs) = IntBag (x : xs)
  clist (IntBag xs) = xs

-- associated data family
class Shape s where
  data Dim s
  area :: Dim s -> Double

data Square
data Rect
instance Shape Square where
  data Dim Square = Side Double
  area (Side a) = a * a
instance Shape Rect where
  data Dim Rect = WH Double Double
  area (WH w h) = w * h

-- type-level naturals with DataKinds
data Nat = Z | S Nat
type family Add (a :: Nat) (b :: Nat) :: Nat where
  Add 'Z b = b
  Add ('S a) b = 'S (Add a b)

data Vec (n :: Nat) a where
  Nil  :: Vec 'Z a
  Cons :: a -> Vec n a -> Vec ('S n) a

append :: Vec n a -> Vec m a -> Vec (Add n m) a
append Nil ys = ys
append (Cons x xs) ys = Cons x (append xs ys)

toList :: Vec n a -> [a]
toList Nil = []
toList (Cons x xs) = x : toList xs

main :: IO ()
main = do
  print (toL (insert 1 (insert 2 (empty :: [Int]))))
  print (swapInt 3, swapChar 'a')
  print (clist (cinsert 7 (IntBag [8, 9])))
  print (area (Side 3), area (WH 2 5))
  print (toList (append (Cons 'a' (Cons 'b' Nil)) (Cons 'c' Nil)))
