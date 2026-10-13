-- Data.Dynamic (base): only Typeable here (Data.Typeable has the class
-- without type representations, so there is no safe fromDynamic).
module Data.Dynamic (Typeable) where

import Data.Typeable (Typeable)
