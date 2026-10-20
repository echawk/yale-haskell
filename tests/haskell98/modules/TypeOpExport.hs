{-# LANGUAGE TypeOperators, ExplicitNamespaces #-}
module TypeOpExport (Pair(..), type (:!:), type (+++), mk) where
data Pair a b = !a :!: !b deriving Show
type (:!:) = Pair
type a +++ b = Either a b
mk :: a -> b -> a :!: b
mk = (:!:)
