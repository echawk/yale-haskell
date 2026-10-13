-- Data.Data (base): only the class, so that deriving Data and Data
-- contexts compile (as Data.Typeable; GHC-EXTENSIONS.md tier 3).
-- gfoldl and the rest of generic programming are not provided.
module Data.Data (Data, Typeable, Proxy(Proxy)) where

import Data.Typeable

class Typeable a => Data a
