-- Data.Coerce (base): coerce between a newtype and its representation.
-- There is no Coercible class: coerce has the type a -> b, so a program
-- GHC accepts runs the same, but a wrong coerce is not rejected.
module Data.Coerce (coerce) where

import Unsafe.Coerce (unsafeCoerce)

coerce :: a -> b
coerce = unsafeCoerce
