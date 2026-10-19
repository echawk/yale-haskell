{-# LANGUAGE TypeFamilies #-}
module AssocFamilyExport (Container(..)) where
class Container f where
  type Elem f
  empty :: f
  insert :: Elem f -> f -> f
  toL :: f -> [Elem f]
instance Container [a] where
  type Elem [a] = a
  empty = []
  insert = (:)
  toL = id
