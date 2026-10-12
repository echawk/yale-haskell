-- Data.Bool (base)
module Data.Bool (Bool(False, True), (&&), (||), not, otherwise, bool) where

bool :: a -> a -> Bool -> a
bool f t b = if b then t else f
