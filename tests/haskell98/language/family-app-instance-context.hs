{-# LANGUAGE TypeFamilies, FlexibleContexts #-}
-- A dictionary whose instance's context is at a type family application
-- not decided yet: Functor (Compose (F p) (F q)) needs Functor (F p),
-- given by the signature (profunctors' Data.Profunctor.Composition).
import Data.Functor.Compose
import Data.Kind (Type)

type family F p :: Type -> Type
type instance F Bool = Maybe
type instance F Char = []

both :: (Functor (F p), Functor (F q)) => proxy p -> proxy q -> Compose (F p) (F q) Int -> Compose (F p) (F q) Int
both _ _ = fmap (* 2)

main :: IO ()
main = print (getCompose (both (Nothing :: Maybe Bool) (Nothing :: Maybe Char) (Compose (Just [1, 2]))))
