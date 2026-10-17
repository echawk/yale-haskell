-- Data.Coerce (base): coerce between a newtype and its representation.
-- There is no Coercible check: coerce has the type a -> b, so a program
-- GHC accepts runs the same, but a wrong coerce is not rejected.
-- Coercible is a class every pair of types is an instance of, for
-- signatures that mention it (Coercible a b => ...).
module Data.Coerce (coerce, Coercible) where

import Unsafe.Coerce (unsafeCoerce)

coerce :: a -> b
coerce = unsafeCoerce

class Coercible a b
instance Coercible a b
