-- Data.HashSet (unordered-containers): a HashMap to ().
module Data.HashSet (
    HashSet, empty, singleton, null, size, member, insert, delete, union,
    unions, difference, intersection, map, filter, foldr, foldl', toList,
    fromList, toMap, fromMap, isSubsetOf
  ) where

import Prelude hiding (null, map, filter, foldr)
import qualified Prelude as P
import qualified Data.List as L
import qualified Data.Foldable as F
import Data.Hashable (Hashable(hashWithSalt))
import qualified Data.HashMap.Base as M
import PreludeModern (Semigroup((<>)), Monoid(mempty))
import Control.DeepSeq (NFData(rnf))

newtype HashSet a = HashSet (M.HashMap a ())

toMap :: HashSet a -> M.HashMap a ()
toMap (HashSet m) = m

fromMap :: M.HashMap a () -> HashSet a
fromMap = HashSet

empty :: HashSet a
empty = HashSet M.empty

singleton :: Hashable a => a -> HashSet a
singleton x = HashSet (M.singleton x ())

null :: HashSet a -> Bool
null = M.null . toMap

size :: HashSet a -> Int
size = M.size . toMap

member :: (Eq a, Hashable a) => a -> HashSet a -> Bool
member x = M.member x . toMap

insert :: (Eq a, Hashable a) => a -> HashSet a -> HashSet a
insert x (HashSet m) = HashSet (M.insert x () m)

delete :: (Eq a, Hashable a) => a -> HashSet a -> HashSet a
delete x (HashSet m) = HashSet (M.delete x m)

union :: (Eq a, Hashable a) => HashSet a -> HashSet a -> HashSet a
union (HashSet a) (HashSet b) = HashSet (M.union a b)

unions :: (Eq a, Hashable a) => [HashSet a] -> HashSet a
unions = L.foldl' union empty

difference :: (Eq a, Hashable a) => HashSet a -> HashSet a -> HashSet a
difference (HashSet a) (HashSet b) = HashSet (M.difference a b)

intersection :: (Eq a, Hashable a) => HashSet a -> HashSet a -> HashSet a
intersection (HashSet a) (HashSet b) = HashSet (M.intersection a b)

map :: (Eq b, Hashable b) => (a -> b) -> HashSet a -> HashSet b
map f = fromList . P.map f . toList

filter :: (a -> Bool) -> HashSet a -> HashSet a
filter p (HashSet m) = HashSet (M.filterWithKey (\k _ -> p k) m)

foldr :: (a -> b -> b) -> b -> HashSet a -> b
foldr f z = P.foldr f z . toList

foldl' :: (b -> a -> b) -> b -> HashSet a -> b
foldl' f z = L.foldl' f z . toList

toList :: HashSet a -> [a]
toList = M.keys . toMap

fromList :: (Eq a, Hashable a) => [a] -> HashSet a
fromList = L.foldl' (flip insert) empty

isSubsetOf :: (Eq a, Hashable a) => HashSet a -> HashSet a -> Bool
isSubsetOf a b = P.all (`member` b) (toList a)

instance Eq a => Eq (HashSet a) where
  HashSet a == HashSet b = a == b

instance Show a => Show (HashSet a) where
  showsPrec d s = showParen (d > 10) (showString "fromList " . shows (toList s))

instance F.Foldable HashSet where
  foldr = foldr
  length = size
  null = null

instance (Eq a, Hashable a) => Semigroup (HashSet a) where
  (<>) = union

instance (Eq a, Hashable a) => Monoid (HashSet a) where
  mempty = empty

instance NFData a => NFData (HashSet a) where
  rnf s = rnf (toList s)

instance Hashable a => Hashable (HashSet a) where
  hashWithSalt s = hashWithSalt s . toMap
