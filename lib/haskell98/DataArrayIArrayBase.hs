-- The IArray class of immutable arrays (array's Data.Array.Base, which
-- Data.Array.Base and Data.Array.IArray re-export), with Array (and
-- UArray, which is Array here) as its instance.  numElements and unsafeAt
-- are methods, as in the array package.
module DataArrayIArrayBase (IArray(..)) where

import qualified Data.Array as A
import Data.Array (Array)
import Ix (Ix(rangeSize))
import BasePrims (primUnsafePerformIO, primReadMutArr, primArrayToMutArr)

infixl 9 !

class IArray a e where
  bounds      :: Ix i => a i e -> (i, i)
  (!)         :: Ix i => a i e -> i -> e
  array       :: Ix i => (i, i) -> [(i, e)] -> a i e
  listArray   :: Ix i => (i, i) -> [e] -> a i e
  elems       :: Ix i => a i e -> [e]
  numElements :: Ix i => a i e -> Int
  -- the element at an offset (0 .. numElements - 1)
  unsafeAt    :: Ix i => a i e -> Int -> e

  numElements arr = rangeSize (bounds arr)
  unsafeAt arr k = elems arr !! k

instance IArray Array e where
  bounds = A.bounds
  (!) = (A.!)
  array = A.array
  listArray = A.listArray
  elems = A.elems
  numElements arr = rangeSize (A.bounds arr)
  unsafeAt arr k = primUnsafePerformIO (primReadMutArr (primArrayToMutArr arr) k)
