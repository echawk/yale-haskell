{-# LANGUAGE TypeOperators, ExistentialQuantification, ScopedTypeVariables #-}
-- Type.Reflection (base): type-indexed TypeReps, over Data.Typeable's.
module Type.Reflection (
    Typeable, TypeRep, typeRep, typeOf, SomeTypeRep(SomeTypeRep),
    someTypeRep, typeRepTyCon, eqTypeRep, (:~~:)(HRefl), TyCon, tyConName
  ) where

import Data.Typeable (Typeable, TyCon, tyConName, Proxy(Proxy))
import qualified Data.Typeable as T
import Data.Type.Equality ((:~~:)(HRefl))
import Unsafe.Coerce (unsafeCoerce)

newtype TypeRep a = TypeRep T.TypeRep

instance Eq (TypeRep a) where
  TypeRep a == TypeRep b = a == b
instance Ord (TypeRep a) where
  compare (TypeRep a) (TypeRep b) = compare a b
instance Show (TypeRep a) where
  showsPrec p (TypeRep r) = showsPrec p r

typeRep :: Typeable a => TypeRep a
typeRep = r
  where r = TypeRep (T.typeRep (proxyOf r))
        proxyOf :: TypeRep a -> Proxy a
        proxyOf _ = Proxy

typeOf :: Typeable a => a -> TypeRep a
typeOf _ = typeRep

data SomeTypeRep = forall a . SomeTypeRep (TypeRep a)

instance Eq SomeTypeRep where
  SomeTypeRep (TypeRep a) == SomeTypeRep (TypeRep b) = a == b
instance Show SomeTypeRep where
  showsPrec p (SomeTypeRep r) = showsPrec p r

someTypeRep :: Typeable a => proxy a -> SomeTypeRep
someTypeRep p = SomeTypeRep (TypeRep (T.typeRep p))

typeRepTyCon :: TypeRep a -> TyCon
typeRepTyCon (TypeRep r) = T.typeRepTyCon r

eqTypeRep :: TypeRep a -> TypeRep b -> Maybe (a :~~: b)
eqTypeRep (TypeRep a) (TypeRep b)
  | a == b = Just (unsafeCoerce (HRefl :: () :~~: ()))
  | otherwise = Nothing
