{-# LANGUAGE KindSignatures, RankNTypes, StandaloneKindSignatures #-}
import Data.Kind (Type)
type Wrap :: (Type -> Type) -> Type -> Type
type Wrap = Maybe' :: ((Type -> Type) -> Type -> Type)
newtype Maybe' f a = M (f a)
unM :: Wrap f a -> f a
unM (M x) = x
main = print (unM (M [1, 2, 3 :: Int]))
