-- Data.List as in GHC's base, for --modern-prelude (modules under
-- lib/haskell98/modern/ are found before the library's own): the 2010
-- Report's, but the functions base generalized are Foldable's (foldl,
-- length, maximumBy, find, ...) and Traversable's (mapAccumL, mapAccumR).
module Data.List (
    (++), head, last, tail, init, null, length, map, reverse,
    intersperse, intercalate, transpose, subsequences, permutations,
    foldl, foldl', foldl1, foldl1', foldr, foldr1,
    concat, concatMap, and, or, any, all, sum, product, maximum, minimum,
    scanl, scanl1, scanr, scanr1, mapAccumL, mapAccumR,
    iterate, repeat, replicate, cycle, unfoldr,
    take, drop, splitAt, takeWhile, dropWhile, span, break, stripPrefix,
    group, inits, tails, isPrefixOf, isSuffixOf, isInfixOf,
    elem, notElem, lookup, find, filter, partition,
    (!!), elemIndex, elemIndices, findIndex, findIndices,
    zip, zip3, zip4, zip5, zip6, zip7,
    zipWith, zipWith3, zipWith4, zipWith5, zipWith6, zipWith7,
    unzip, unzip3, unzip4, unzip5, unzip6, unzip7,
    lines, words, unlines, unwords,
    nub, delete, (\\), union, intersect, sort, insert,
    nubBy, deleteBy, deleteFirstsBy, unionBy, intersectBy, groupBy,
    sortBy, insertBy, maximumBy, minimumBy,
    genericLength, genericTake, genericDrop, genericSplitAt, genericIndex,
    genericReplicate,
    dropWhileEnd, sortOn, isSubsequenceOf, uncons, unsnoc, singleton,
    scanl', iterate', (!?)
  ) where

import Prelude hiding (foldr, foldl, foldr1, foldl1, null, length, elem, notElem,
                       maximum, minimum, sum, product, concat, concatMap, and,
                       or, any, all)
import DataListBase hiding (foldl, foldl', foldl1, foldr, foldr1,
                       null, length, elem, notElem, maximum, minimum, sum,
                       product, concat, concatMap, and, or, any, all, find,
                       maximumBy, minimumBy, mapAccumL, mapAccumR)
import Data.Foldable (Foldable(foldr, foldl, foldl', foldr1, foldl1, null,
                       length, elem, maximum, minimum, sum, product),
                      concat, concatMap, and, or, any, all, maximumBy,
                      minimumBy, notElem, find)
import Data.Traversable (mapAccumL, mapAccumR)
