-- The Haskell 98 Array library.
--
-- The definitions are in the Prelude's internal module PreludeArray
-- (Yale's constant-time implementation, changed to take (index, value)
-- pairs as H98 requires), because the compiler knows the Array type.
-- Missing: instance Functor (Array a) (needs constructor classes); use
-- the Yale extension amap meanwhile, which is not exported here.

module Array (
    Ix.., Array, array, listArray, (!), bounds, indices, elems, assocs,
    accumArray, (//), accum, ixmap ) where

import Ix
import PreludeArray(Array, array, listArray, (!), bounds, indices, elems,
		    assocs, accumArray, (//), accum, ixmap)
