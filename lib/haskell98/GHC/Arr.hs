-- GHC.Arr (base): Data.Array, and the unchecked operations, which are
-- checked here.
module GHC.Arr (
    module Data.Array, unsafeIndex, unsafeRangeSize, unsafeAt, numElements,
    amap, STArray, boundsSTArray, numElementsSTArray, unsafeReadSTArray,
    unsafeWriteSTArray, freezeSTArray, unsafeFreezeSTArray, thawSTArray,
    unsafeThawSTArray
  ) where

import Data.Array
import Data.Array.Base (STArray, boundsSTArray, numElementsSTArray,
  unsafeReadSTArray, unsafeWriteSTArray, freezeSTArray, unsafeFreezeSTArray,
  thawSTArray, unsafeThawSTArray)

unsafeIndex :: Ix i => (i, i) -> i -> Int
unsafeIndex = index

unsafeRangeSize :: Ix i => (i, i) -> Int
unsafeRangeSize = rangeSize

unsafeAt :: Ix i => Array i e -> Int -> e
unsafeAt a n = elems a !! n

numElements :: Ix i => Array i e -> Int
numElements = rangeSize . bounds

amap :: Ix i => (a -> b) -> Array i a -> Array i b
amap = fmap
