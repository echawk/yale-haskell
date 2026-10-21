-- Data.Array.IArray (array): the IArray class of immutable arrays, with
-- Array (and UArray, which is Array here) as its instance; the functions
-- not in the class are defined over it, as the array package does.
module Data.Array.IArray (
    IArray(bounds, (!), array, listArray, elems), Array, UArray,
    Ix(range, index, inRange, rangeSize),
    indices, assocs, (//), accum, accumArray, amap, ixmap, numElements,
    (!?)
  ) where

import qualified Data.Array as A
import Data.Array (Array)
import Ix (Ix(range, index, inRange, rangeSize))
import Data.Array.Base (UArray)

infixl 9 !, //

class IArray a e where
  bounds    :: Ix i => a i e -> (i, i)
  (!)       :: Ix i => a i e -> i -> e
  array     :: Ix i => (i, i) -> [(i, e)] -> a i e
  listArray :: Ix i => (i, i) -> [e] -> a i e
  elems     :: Ix i => a i e -> [e]

instance IArray Array e where
  bounds = A.bounds
  (!) = (A.!)
  array = A.array
  listArray = A.listArray
  elems = A.elems

indices :: (IArray a e, Ix i) => a i e -> [i]
indices arr = range (bounds arr)

assocs :: (IArray a e, Ix i) => a i e -> [(i, e)]
assocs arr = [(i, arr ! i) | i <- indices arr]

(//) :: (IArray a e, Ix i) => a i e -> [(i, e)] -> a i e
arr // ies = array (bounds arr) (assocs arr ++ ies)

accum :: (IArray a e, Ix i) => (e -> e' -> e) -> a i e -> [(i, e')] -> a i e
accum f arr ies = listArray (bounds arr)
  (A.elems (A.accum f (A.listArray (bounds arr) (elems arr)) ies))

accumArray :: (IArray a e, Ix i) => (e -> e' -> e) -> e -> (i, i) -> [(i, e')] -> a i e
accumArray f z b ies = listArray b (A.elems (A.accumArray f z b ies))

amap :: (IArray a e', IArray a e, Ix i) => (e' -> e) -> a i e' -> a i e
amap f arr = listArray (bounds arr) (map f (elems arr))

ixmap :: (IArray a e, Ix i, Ix j) => (i, i) -> (i -> j) -> a j e -> a i e
ixmap b f arr = listArray b [arr ! f i | i <- range b]

numElements :: (IArray a e, Ix i) => a i e -> Int
numElements arr = rangeSize (bounds arr)

(!?) :: (IArray a e, Ix i) => a i e -> i -> Maybe e
arr !? i = if inRange (bounds arr) i then Just (arr ! i) else Nothing
