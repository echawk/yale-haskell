{-# LANGUAGE GADTs, TypeOperators, RankNTypes #-}
-- Data.Type.Coercion (base): evidence that two types are Coercible
-- (which Yale Haskell does not check: Data.Coerce).
module Data.Type.Coercion (
    Coercion(Coercion), coerceWith, gcoerceWith, sym, trans, repr,
    TestCoercion(testCoercion)
  ) where

import Data.Coerce (Coercible, coerce)
import Data.Type.Equality ((:~:)(Refl))

data Coercion a b where
  Coercion :: Coercible a b => Coercion a b

instance Show (Coercion a b) where
  showsPrec _ Coercion = showString "Coercion"

instance Eq (Coercion a b) where
  _ == _ = True

coerceWith :: Coercion a b -> a -> b
coerceWith Coercion x = coerce x

gcoerceWith :: Coercion a b -> (Coercible a b => r) -> r
gcoerceWith Coercion x = x

sym :: Coercion a b -> Coercion b a
sym Coercion = Coercion

trans :: Coercion a b -> Coercion b c -> Coercion a c
trans Coercion Coercion = Coercion

repr :: (a :~: b) -> Coercion a b
repr Refl = Coercion

class TestCoercion f where
  testCoercion :: f a -> f b -> Maybe (Coercion a b)
