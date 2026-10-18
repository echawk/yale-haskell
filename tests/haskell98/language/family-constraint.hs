-- A constraint on a type family application in a signature
-- (Size (Rep a) =>), as generic-programming libraries write.
{-# LANGUAGE TypeFamilies, FlexibleContexts, KindSignatures, DefaultSignatures #-}
import Data.Kind (Type)
class Box a where
  type Rep a :: Type
  from :: a -> Rep a
class Size r where size :: r -> Int
instance Size Int where size _ = 1
instance Size [b] where size = length
newtype N = N Int
instance Box N where
  type Rep N = Int
  from (N i) = i
newtype L = L String
instance Box L where
  type Rep L = String
  from (L s) = s
gsize :: (Box a, Size (Rep a)) => a -> Int
gsize = size . from
main = print (gsize (N 3), gsize (L "abcd"))
