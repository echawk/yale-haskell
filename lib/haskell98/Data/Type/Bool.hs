{-# LANGUAGE DataKinds, TypeFamilies, TypeOperators, PolyKinds #-}
-- Data.Type.Bool (base): type-level Booleans.
module Data.Type.Bool (If, type (&&), type (||), Not) where

type family If (c :: Bool) (t :: k) (e :: k) :: k where
  If 'True t e = t
  If 'False t e = e

infixr 3 &&
type family (a :: Bool) && (b :: Bool) :: Bool where
  'False && a = 'False
  'True && a = a

infixr 2 ||
type family (a :: Bool) || (b :: Bool) :: Bool where
  'False || a = a
  'True || a = 'True

type family Not (a :: Bool) :: Bool where
  Not 'False = 'True
  Not 'True = 'False
