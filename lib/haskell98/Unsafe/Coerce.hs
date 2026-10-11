-- Unsafe.Coerce (base): a value as any type.  Sound only between types
-- with the same representation (a newtype and its field).
module Unsafe.Coerce (unsafeCoerce) where

import PreludePrims (primUnsafeCoerce)

unsafeCoerce :: a -> b
unsafeCoerce = primUnsafeCoerce
