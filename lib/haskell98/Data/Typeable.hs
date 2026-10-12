-- Data.Typeable (base): only the class, so that deriving Typeable
-- compiles (an empty instance).  typeOf and casts need run-time type
-- representations, which Yale Haskell does not keep.
module Data.Typeable (Typeable, Proxy(Proxy)) where

import Data.Proxy (Proxy(Proxy))

class Typeable a
