-- The Haskell 98 Array library.
--
-- The definitions are in the Prelude's internal module PreludeArray
-- (Yale's constant-time implementation, changed to take (index, value)
-- pairs as H98 requires), because the compiler knows the Array type.
-- The Functor instance is there too (fmap is amap).

module Array (
    Ix.., Array, array, listArray, (!), bounds, indices, elems, assocs,
    accumArray, (//), accum, ixmap ) where

import Ix
import PreludeArray(Array, array, listArray, (!), bounds, indices, elems,
		    assocs, accumArray, (//), accum, ixmap)
