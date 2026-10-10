-- Data.Array.IArray (array), without the IArray class: its functions are
-- Data.Array's, for Array (and UArray, which is Array here).
module Data.Array.IArray (module Data.Array, UArray, (!?)) where

import Data.Array
import Data.Array.Base (UArray)

(!?) :: Ix i => Array i e -> i -> Maybe e
arr !? i = if inRange (bounds arr) i then Just (arr ! i) else Nothing
