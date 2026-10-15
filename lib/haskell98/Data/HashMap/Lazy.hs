-- Data.HashMap.Lazy (unordered-containers): Data.HashMap.Base's HashMap.
module Data.HashMap.Lazy (
    HashMap, empty, singleton, null, size, member, lookup, (!?), (!), findWithDefault,
    lookupDefault, insert, insertWith, delete, adjust, update, alter, union,
    unionWith, unionWithKey, unions, map, mapWithKey, traverseWithKey,
    mapMaybe, mapMaybeWithKey, filter, filterWithKey, foldr, foldr', foldl',
    foldrWithKey, foldlWithKey', foldMapWithKey, difference, differenceWith,
    intersection, intersectionWith, intersectionWithKey, keys, elems, toList,
    fromList, fromListWith, fromListWithKey, isSubmapOf
  ) where

import Prelude ()
import Data.HashMap.Base
