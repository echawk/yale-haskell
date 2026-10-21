-- Data.Array.MArray (array)
module Data.Array.MArray (
    MArray(getBounds, getNumElements, newArray, newArray_, unsafeNewArray_, unsafeRead, unsafeWrite),
    readArray, writeArray, modifyArray, modifyArray',
    newListArray, newGenArray, getElems, getAssocs, mapArray,
    freeze, thaw, unsafeFreeze, unsafeThaw, module Data.Ix
  ) where

import Data.Array.Base
import Data.Ix
