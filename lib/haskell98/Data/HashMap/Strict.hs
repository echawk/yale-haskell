-- Data.HashMap.Strict (unordered-containers): the same HashMap as .Lazy,
-- whose functions here evaluate each value they store.
module Data.HashMap.Strict (
    HashMap, empty, singleton, null, size, member, lookup, (!?), (!), findWithDefault,
    lookupDefault, insert, insertWith, delete, adjust, update, alter, alterF, union,
    unionWith, unionWithKey, unions, map, mapWithKey, traverseWithKey,
    mapMaybe, mapMaybeWithKey, filter, filterWithKey, foldr, foldr', foldl',
    foldrWithKey, foldlWithKey', foldMapWithKey, difference, differenceWith,
    intersection, intersectionWith, intersectionWithKey, keys, elems, toList,
    fromList, fromListWith, fromListWithKey, isSubmapOf
  ) where

import Prelude hiding (lookup, map, filter, null, foldr)
import Data.Hashable (Hashable)
import qualified Data.List as L
import Data.HashMap.Base hiding (singleton, insert, insertWith, adjust, alter,
    update, map, mapWithKey, fromList, fromListWith, fromListWithKey, unionWith,
    unionWithKey, unions, union, mapMaybe, mapMaybeWithKey, intersectionWith,
    intersectionWithKey)
import qualified Data.HashMap.Base as B

singleton :: Hashable k => k -> v -> HashMap k v
singleton k v = v `seq` B.singleton k v

insert :: (Eq k, Hashable k) => k -> v -> HashMap k v -> HashMap k v
insert k v m = v `seq` B.insert k v m

alter :: (Eq k, Hashable k) => (Maybe v -> Maybe v) -> k -> HashMap k v -> HashMap k v
alter f = B.alter (\mv -> case f mv of
                            Nothing -> Nothing
                            Just v -> v `seq` Just v)

insertWith :: (Eq k, Hashable k) => (v -> v -> v) -> k -> v -> HashMap k v -> HashMap k v
insertWith f k v = alter (Just . maybe v (f v)) k

adjust :: (Eq k, Hashable k) => (v -> v) -> k -> HashMap k v -> HashMap k v
adjust f = alter (fmap f)

update :: (Eq k, Hashable k) => (v -> Maybe v) -> k -> HashMap k v -> HashMap k v
update f = alter (>>= f)

mapWithKey :: (k -> v1 -> v2) -> HashMap k v1 -> HashMap k v2
mapWithKey f m = let r = B.mapWithKey f m in L.foldl' (flip seq) () (elems r) `seq` r

map :: (v1 -> v2) -> HashMap k v1 -> HashMap k v2
map f = mapWithKey (const f)

mapMaybeWithKey :: (k -> v1 -> Maybe v2) -> HashMap k v1 -> HashMap k v2
mapMaybeWithKey f m = let r = B.mapMaybeWithKey f m in L.foldl' (flip seq) () (elems r) `seq` r

mapMaybe :: (v1 -> Maybe v2) -> HashMap k v1 -> HashMap k v2
mapMaybe f = mapMaybeWithKey (const f)

fromList :: (Eq k, Hashable k) => [(k, v)] -> HashMap k v
fromList = L.foldl' (\m (k, v) -> insert k v m) empty

fromListWith :: (Eq k, Hashable k) => (v -> v -> v) -> [(k, v)] -> HashMap k v
fromListWith f = L.foldl' (\m (k, v) -> insertWith f k v m) empty

fromListWithKey :: (Eq k, Hashable k) => (k -> v -> v -> v) -> [(k, v)] -> HashMap k v
fromListWithKey f = L.foldl' (\m (k, v) -> insertWith (f k) k v m) empty

unionWithKey :: (Eq k, Hashable k) => (k -> v -> v -> v) -> HashMap k v -> HashMap k v -> HashMap k v
unionWithKey f a b = L.foldl' (\m (k, v) -> alter (Just . maybe v (\old -> f k old v)) k m) a (toList b)

unionWith :: (Eq k, Hashable k) => (v -> v -> v) -> HashMap k v -> HashMap k v -> HashMap k v
unionWith f = unionWithKey (const f)

union :: (Eq k, Hashable k) => HashMap k v -> HashMap k v -> HashMap k v
union = B.union

unions :: (Eq k, Hashable k) => [HashMap k v] -> HashMap k v
unions = B.unions

intersectionWithKey :: (Eq k, Hashable k) => (k -> v1 -> v2 -> v3) -> HashMap k v1 -> HashMap k v2 -> HashMap k v3
intersectionWithKey f a b = mapMaybeWithKey (\k v -> fmap (f k v) (lookup k b)) a

intersectionWith :: (Eq k, Hashable k) => (v1 -> v2 -> v3) -> HashMap k v1 -> HashMap k v2 -> HashMap k v3
intersectionWith f = intersectionWithKey (const f)
