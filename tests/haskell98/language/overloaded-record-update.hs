{-# LANGUAGE OverloadedRecordDot, OverloadedRecordUpdate, RebindableSyntax, DataKinds, TypeApplications, AllowAmbiguousTypes, FunctionalDependencies, FlexibleInstances, MultiParamTypeClasses, ScopedTypeVariables #-}
import Prelude
class HasField x r a | x r -> a where hasField :: r -> (a -> r, a)
getField :: forall x r a . HasField x r a => r -> a
getField = snd . hasField @x
setField :: forall x r a . HasField x r a => a -> r -> r
setField v r = fst (hasField @x r) v
data P = P { px :: Int, py :: Int } deriving Show
instance HasField "px" P Int where hasField r@(P _ y) = (\v -> P v y, px' r)
instance HasField "py" P Int where hasField r@(P x _) = (\v -> P x v, py' r)
px' (P x _) = x
py' (P _ y) = y
main = print ((P 1 2) { px = 5 :: Int, py = 6 :: Int }, (getField @"px" (P 7 8) :: Int))
