-- Type families whose result is a type constructor, applied to more
-- arguments than they have (GHC.Generics' Rep1 f a).
{-# LANGUAGE TypeFamilies, KindSignatures, DataKinds #-}
import Data.Kind (Type)
data Sel = One | Many
type family F (b :: Sel) :: Type -> Type
type instance F 'One = Maybe
type instance F 'Many = []
class C a where
  type R a :: Type -> Type
  wrap :: a -> R a Int
instance C Bool where
  type R Bool = Maybe
  wrap b = if b then Just 1 else Nothing
x :: F 'One Int
x = Just 3
y :: F 'Many Char
y = "abc"
main = print (x, y, wrap True)
