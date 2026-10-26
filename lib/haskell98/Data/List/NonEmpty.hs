-- Data.List.NonEmpty (base): lists with at least one element.
module Data.List.NonEmpty (
    NonEmpty((:|)), map, head, tail, last, init, toList, fromList,
    nonEmpty, cons, (<|), length, reverse, sort, sortBy, sortOn, sortWith,
    zip, zipWith, unzip, nub, groupBy, group, groupWith, groupAllWith,
    group1, filter, partition, takeWhile, dropWhile, span, break, take,
    drop, splitAt, iterate, repeat, cycle, insert, scanl, scanr, scanl1,
    scanr1, transpose, xor, unfoldr, some1, (!!), uncons, singleton,
    appendList, prependList, groupBy1, groupWith1, groupAllWith1, inits1,
    tails1, permutations, permutations1, intersperse, inits, tails, append
  ) where

import Prelude hiding (map, head, tail, last, init, length, reverse, zip,
                       zipWith, unzip, filter, takeWhile, dropWhile, span,
                       break, take, drop, splitAt, iterate, repeat, cycle,
                       scanl, scanr, scanl1, scanr1, (!!))
import qualified Prelude as P
import PreludeModern (Applicative(pure, (<*>)), Alternative(many), liftA2,
                      Semigroup((<>)), Foldable(foldr, null),
                      Traversable(traverse), NonEmpty((:|)))
import qualified PreludeModern as F
import qualified Data.List as L
import Data.Ord (comparing)

infixr 5 <|

-- The class instances are PreludeModern's, with the type, as base has
-- them wherever NonEmpty is.

map :: (a -> b) -> NonEmpty a -> NonEmpty b
map = fmap

head :: NonEmpty a -> a
head (x :| _) = x

tail :: NonEmpty a -> [a]
tail (_ :| xs) = xs

last :: NonEmpty a -> a
last (x :| xs) = P.last (x : xs)

init :: NonEmpty a -> [a]
init (x :| xs) = P.init (x : xs)

toList :: NonEmpty a -> [a]
toList (x :| xs) = x : xs

fromList :: [a] -> NonEmpty a
fromList (x : xs) = x :| xs
fromList [] = error "NonEmpty.fromList: empty list"

nonEmpty :: [a] -> Maybe (NonEmpty a)
nonEmpty [] = Nothing
nonEmpty (x : xs) = Just (x :| xs)

singleton :: a -> NonEmpty a
singleton x = x :| []

uncons :: NonEmpty a -> (a, Maybe (NonEmpty a))
uncons (x :| xs) = (x, nonEmpty xs)

cons, (<|) :: a -> NonEmpty a -> NonEmpty a
cons y (x :| xs) = y :| (x : xs)
(<|) = cons

appendList :: NonEmpty a -> [a] -> NonEmpty a
appendList (x :| xs) ys = x :| (xs ++ ys)

prependList :: [a] -> NonEmpty a -> NonEmpty a
prependList ls ne = case ls of
  [] -> ne
  (x : xs) -> x :| (xs ++ toList ne)

length :: NonEmpty a -> Int
length (_ :| xs) = 1 + P.length xs

lift :: ([a] -> [b]) -> NonEmpty a -> NonEmpty b
lift f = fromList . f . toList

reverse :: NonEmpty a -> NonEmpty a
reverse = lift P.reverse

sort :: Ord a => NonEmpty a -> NonEmpty a
sort = lift L.sort

sortBy :: (a -> a -> Ordering) -> NonEmpty a -> NonEmpty a
sortBy f = lift (L.sortBy f)

sortOn, sortWith :: Ord b => (a -> b) -> NonEmpty a -> NonEmpty a
sortOn f = lift (L.sortBy (comparing f))
sortWith = sortOn

zip :: NonEmpty a -> NonEmpty b -> NonEmpty (a, b)
zip (x :| xs) (y :| ys) = (x, y) :| P.zip xs ys

zipWith :: (a -> b -> c) -> NonEmpty a -> NonEmpty b -> NonEmpty c
zipWith f (x :| xs) (y :| ys) = f x y :| P.zipWith f xs ys

unzip :: Functor f => f (a, b) -> (f a, f b)
unzip ps = (fmap fst ps, fmap snd ps)

nub :: Eq a => NonEmpty a -> NonEmpty a
nub = lift L.nub

groupBy :: (a -> a -> Bool) -> [a] -> [NonEmpty a]
groupBy eq = P.map fromList . L.groupBy eq

group :: Eq a => [a] -> [NonEmpty a]
group = groupBy (==)

groupWith :: Eq b => (a -> b) -> [a] -> [NonEmpty a]
groupWith f = groupBy (\x y -> f x == f y)

groupAllWith :: Ord b => (a -> b) -> [a] -> [NonEmpty a]
groupAllWith f = groupWith f . L.sortBy (comparing f)

group1 :: Eq a => NonEmpty a -> NonEmpty (NonEmpty a)
group1 = fromList . group . toList

groupBy1 :: (a -> a -> Bool) -> NonEmpty a -> NonEmpty (NonEmpty a)
groupBy1 eq = fromList . groupBy eq . toList

groupWith1 :: Eq b => (a -> b) -> NonEmpty a -> NonEmpty (NonEmpty a)
groupWith1 f = groupBy1 (\x y -> f x == f y)

groupAllWith1 :: Ord b => (a -> b) -> NonEmpty a -> NonEmpty (NonEmpty a)
groupAllWith1 f = groupWith1 f . fromList . L.sortBy (comparing f) . toList

inits1 :: NonEmpty a -> NonEmpty (NonEmpty a)
inits1 = fromList . P.map fromList . P.drop 1 . L.inits . toList

tails1 :: NonEmpty a -> NonEmpty (NonEmpty a)
tails1 = fromList . P.map fromList . P.init . L.tails . toList

permutations :: [a] -> NonEmpty [a]
permutations = fromList . L.permutations

permutations1 :: NonEmpty a -> NonEmpty (NonEmpty a)
permutations1 = fromList . P.map fromList . L.permutations . toList

filter :: (a -> Bool) -> NonEmpty a -> [a]
filter p = P.filter p . toList

partition :: (a -> Bool) -> NonEmpty a -> ([a], [a])
partition p = L.partition p . toList

takeWhile, dropWhile :: (a -> Bool) -> NonEmpty a -> [a]
takeWhile p = P.takeWhile p . toList
dropWhile p = P.dropWhile p . toList

span, break :: (a -> Bool) -> NonEmpty a -> ([a], [a])
span p = P.span p . toList
break p = P.break p . toList

take, drop :: Int -> NonEmpty a -> [a]
take n = P.take n . toList
drop n = P.drop n . toList

splitAt :: Int -> NonEmpty a -> ([a], [a])
splitAt n = P.splitAt n . toList

(!!) :: NonEmpty a -> Int -> a
ne !! n = toList ne P.!! n

iterate :: (a -> a) -> a -> NonEmpty a
iterate f x = x :| P.iterate f (f x)

repeat :: a -> NonEmpty a
repeat x = x :| P.repeat x

cycle :: NonEmpty a -> NonEmpty a
cycle = lift P.cycle

insert :: Ord a => a -> [a] -> NonEmpty a
insert x = fromList . L.insert x

scanl :: (b -> a -> b) -> b -> [a] -> NonEmpty b
scanl f z = fromList . P.scanl f z

scanr :: (a -> b -> b) -> b -> [a] -> NonEmpty b
scanr f z = fromList . P.scanr f z

scanl1, scanr1 :: (a -> a -> a) -> NonEmpty a -> NonEmpty a
scanl1 f = lift (P.scanl1 f)
scanr1 f = lift (P.scanr1 f)

transpose :: NonEmpty (NonEmpty a) -> NonEmpty (NonEmpty a)
transpose = fromList . P.map fromList . L.transpose . toList . fmap toList

xor :: NonEmpty Bool -> Bool
xor (x :| xs) = P.foldr (/=) x xs

unfoldr :: (a -> (b, Maybe a)) -> a -> NonEmpty b
unfoldr f a = case f a of
  (b, Nothing) -> b :| []
  (b, Just a') -> b <| unfoldr f a'

some1 :: Alternative f => f a -> f (NonEmpty a)
some1 x = liftA2 (:|) x (many x)

intersperse :: a -> NonEmpty a -> NonEmpty a
intersperse sep (x :| xs) = x :| concatMap (\y -> [sep, y]) xs

inits :: F.Foldable f => f a -> NonEmpty [a]
inits = fromList . L.inits . F.toList

tails :: F.Foldable f => f a -> NonEmpty [a]
tails = fromList . L.tails . F.toList

append :: NonEmpty a -> NonEmpty a -> NonEmpty a
append (x :| xs) (y :| ys) = x :| (xs ++ y : ys)
