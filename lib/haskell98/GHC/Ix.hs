-- GHC.Ix (base): the Ix class, with GHC's unchecked index and size.
module GHC.Ix (Ix(range, index, inRange, rangeSize), unsafeIndex, unsafeRangeSize) where

import Ix (Ix(range, index, inRange, rangeSize))

unsafeIndex :: Ix a => (a, a) -> a -> Int
unsafeIndex = index

unsafeRangeSize :: Ix a => (a, a) -> Int
unsafeRangeSize = rangeSize
