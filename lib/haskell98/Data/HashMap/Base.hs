-- Data.HashMap.Base: unordered-containers' HashMap for Yale Haskell, an
-- IntMap from a key's hash to the (key, value) pairs with that hash.  It
-- needs only Eq and Hashable on keys, as the real one; the order of
-- toList is by hash, as there (the hashes themselves differ).
-- Data.HashMap.Lazy and .Strict export it; .Strict's functions evaluate
-- values as they are stored.
module Data.HashMap.Base where

import Prelude hiding (lookup, map, filter, null, foldr)
import qualified Prelude as P
import qualified Data.List as L
import qualified Data.IntMap as IM
import qualified Data.Foldable as F
import qualified Data.Traversable as T
import Data.Hashable (Hashable(hash, hashWithSalt))
import PreludeModern (Semigroup((<>)), Monoid(mempty), Applicative(pure), (<$>), liftA2)
import Control.DeepSeq (NFData(rnf))

newtype HashMap k v = HashMap (IM.IntMap [(k, v)])

buckets :: HashMap k v -> IM.IntMap [(k, v)]
buckets (HashMap m) = m

empty :: HashMap k v
empty = HashMap IM.empty

singleton :: Hashable k => k -> v -> HashMap k v
singleton k v = HashMap (IM.singleton (hash k) [(k, v)])

null :: HashMap k v -> Bool
null (HashMap m) = IM.null m

size :: HashMap k v -> Int
size (HashMap m) = IM.foldr (\b n -> length b + n) 0 m

member :: (Eq k, Hashable k) => k -> HashMap k v -> Bool
member k m = maybe False (const True) (lookup k m)

lookup :: (Eq k, Hashable k) => k -> HashMap k v -> Maybe v
lookup k (HashMap m) = IM.lookup (hash k) m >>= P.lookup k

(!?) :: (Eq k, Hashable k) => HashMap k v -> k -> Maybe v
m !? k = lookup k m

(!) :: (Eq k, Hashable k) => HashMap k v -> k -> v
m ! k = maybe (error "Data.HashMap.Internal.(!): key not found") id (lookup k m)

findWithDefault, lookupDefault :: (Eq k, Hashable k) => v -> k -> HashMap k v -> v
findWithDefault d k m = maybe d id (lookup k m)
lookupDefault = findWithDefault

infixl 9 !, !?

-- the bucket with K's value replaced by F's result (Nothing: removed)
alterBucket :: Eq k => k -> (Maybe v -> Maybe v) -> [(k, v)] -> [(k, v)]
alterBucket k f b = case P.lookup k b of
  Nothing -> maybe b (\v -> b ++ [(k, v)]) (f Nothing)
  Just old -> case f (Just old) of
    Nothing -> P.filter ((/= k) . fst) b
    Just v -> P.map (\(k', v') -> if k' == k then (k', v) else (k', v')) b

alter :: (Eq k, Hashable k) => (Maybe v -> Maybe v) -> k -> HashMap k v -> HashMap k v
alter f k (HashMap m) = HashMap (IM.alter g (hash k) m)
  where g mb = case alterBucket k f (maybe [] id mb) of
                 [] -> Nothing
                 b -> Just b

insert :: (Eq k, Hashable k) => k -> v -> HashMap k v -> HashMap k v
insert k v = alter (const (Just v)) k

insertWith :: (Eq k, Hashable k) => (v -> v -> v) -> k -> v -> HashMap k v -> HashMap k v
insertWith f k v = alter (Just . maybe v (f v)) k

delete :: (Eq k, Hashable k) => k -> HashMap k v -> HashMap k v
delete = alter (const Nothing)

adjust :: (Eq k, Hashable k) => (v -> v) -> k -> HashMap k v -> HashMap k v
adjust f = alter (fmap f)

update :: (Eq k, Hashable k) => (v -> Maybe v) -> k -> HashMap k v -> HashMap k v
update f = alter (>>= f)

toList :: HashMap k v -> [(k, v)]
toList (HashMap m) = concat (IM.elems m)

fromList :: (Eq k, Hashable k) => [(k, v)] -> HashMap k v
fromList = L.foldl' (\m (k, v) -> insert k v m) empty

fromListWith :: (Eq k, Hashable k) => (v -> v -> v) -> [(k, v)] -> HashMap k v
fromListWith f = L.foldl' (\m (k, v) -> insertWith f k v m) empty

fromListWithKey :: (Eq k, Hashable k) => (k -> v -> v -> v) -> [(k, v)] -> HashMap k v
fromListWithKey f = L.foldl' (\m (k, v) -> insertWith (f k) k v m) empty

keys :: HashMap k v -> [k]
keys = P.map fst . toList

elems :: HashMap k v -> [v]
elems = P.map snd . toList

unionWithKey :: (Eq k, Hashable k) => (k -> v -> v -> v) -> HashMap k v -> HashMap k v -> HashMap k v
unionWithKey f a b = L.foldl' (\m (k, v) -> alter (Just . maybe v (\old -> f k old v)) k m) a (toList b)

unionWith :: (Eq k, Hashable k) => (v -> v -> v) -> HashMap k v -> HashMap k v -> HashMap k v
unionWith f = unionWithKey (const f)

union :: (Eq k, Hashable k) => HashMap k v -> HashMap k v -> HashMap k v
union = unionWith const

unions :: (Eq k, Hashable k) => [HashMap k v] -> HashMap k v
unions = L.foldl' union empty

mapWithKey :: (k -> v1 -> v2) -> HashMap k v1 -> HashMap k v2
mapWithKey f (HashMap m) = HashMap (IM.map (P.map (\(k, v) -> (k, f k v))) m)

map :: (v1 -> v2) -> HashMap k v1 -> HashMap k v2
map f = mapWithKey (const f)

traverseWithKey :: Applicative f => (k -> v1 -> f v2) -> HashMap k v1 -> f (HashMap k v2)
traverseWithKey f (HashMap m) =
  HashMap . IM.fromDistinctAscList <$>
    T.traverse (\(h, b) -> (,) h <$> T.traverse (\(k, v) -> (,) k <$> f k v) b) (IM.toList m)

mapMaybeWithKey :: (k -> v1 -> Maybe v2) -> HashMap k v1 -> HashMap k v2
mapMaybeWithKey f (HashMap m) = HashMap (IM.mapMaybe keep m)
  where keep b = case [(k, v') | (k, v) <- b, Just v' <- [f k v]] of
                   [] -> Nothing
                   b' -> Just b'

mapMaybe :: (v1 -> Maybe v2) -> HashMap k v1 -> HashMap k v2
mapMaybe f = mapMaybeWithKey (const f)

filterWithKey :: (k -> v -> Bool) -> HashMap k v -> HashMap k v
filterWithKey p = mapMaybeWithKey (\k v -> if p k v then Just v else Nothing)

filter :: (v -> Bool) -> HashMap k v -> HashMap k v
filter p = filterWithKey (const p)

foldrWithKey :: (k -> v -> a -> a) -> a -> HashMap k v -> a
foldrWithKey f z m = P.foldr (\(k, v) a -> f k v a) z (toList m)

foldr :: (v -> a -> a) -> a -> HashMap k v -> a
foldr f = foldrWithKey (const f)

foldlWithKey' :: (a -> k -> v -> a) -> a -> HashMap k v -> a
foldlWithKey' f z m = L.foldl' (\a (k, v) -> f a k v) z (toList m)

foldl' :: (a -> v -> a) -> a -> HashMap k v -> a
foldl' f = foldlWithKey' (\a _ v -> f a v)

foldr' :: (v -> a -> a) -> a -> HashMap k v -> a
foldr' = foldr

foldMapWithKey :: Monoid m => (k -> v -> m) -> HashMap k v -> m
foldMapWithKey f = foldrWithKey (\k v m -> f k v <> m) mempty

differenceWith :: (Eq k, Hashable k) => (v -> w -> Maybe v) -> HashMap k v -> HashMap k w -> HashMap k v
differenceWith f a b = mapMaybeWithKey (\k v -> maybe (Just v) (f v) (lookup k b)) a

difference :: (Eq k, Hashable k) => HashMap k v -> HashMap k w -> HashMap k v
difference a b = filterWithKey (\k _ -> not (member k b)) a

intersectionWithKey :: (Eq k, Hashable k) => (k -> v1 -> v2 -> v3) -> HashMap k v1 -> HashMap k v2 -> HashMap k v3
intersectionWithKey f a b = mapMaybeWithKey (\k v -> fmap (f k v) (lookup k b)) a

intersectionWith :: (Eq k, Hashable k) => (v1 -> v2 -> v3) -> HashMap k v1 -> HashMap k v2 -> HashMap k v3
intersectionWith f = intersectionWithKey (const f)

intersection :: (Eq k, Hashable k) => HashMap k v -> HashMap k w -> HashMap k v
intersection = intersectionWith const

isSubmapOf :: (Eq k, Hashable k, Eq v) => HashMap k v -> HashMap k v -> Bool
isSubmapOf a b = P.all (\(k, v) -> lookup k b == Just v) (toList a)

instance (Eq k, Eq v) => Eq (HashMap k v) where
  a == b = size a == size b && P.all (\(k, v) -> case [v' | (k', v') <- toList b, k' == k] of
                                                    [v'] -> v == v'
                                                    _ -> False) (toList a)

instance (Show k, Show v) => Show (HashMap k v) where
  showsPrec d m = showParen (d > 10) (showString "fromList " . shows (toList m))

instance Functor (HashMap k) where
  fmap = map

instance F.Foldable (HashMap k) where
  foldr = foldr
  length = size
  null = null

instance T.Traversable (HashMap k) where
  traverse f = traverseWithKey (const f)

instance (Eq k, Hashable k) => Semigroup (HashMap k v) where
  (<>) = union

instance (Eq k, Hashable k) => Monoid (HashMap k v) where
  mempty = empty

instance (NFData k, NFData v) => NFData (HashMap k v) where
  rnf m = rnf (toList m)

instance (Hashable k, Hashable v) => Hashable (HashMap k v) where
  hashWithSalt s m = hashWithSalt s (IM.toList (buckets m))

-- | The value at K changed by an action (Nothing: absent).
alterF :: (Functor f, Eq k, Hashable k)
       => (Maybe v -> f (Maybe v)) -> k -> HashMap k v -> f (HashMap k v)
alterF f k m = fmap (\r -> case r of
                             Nothing -> delete k m
                             Just v -> insert k v m) (f (lookup k m))
