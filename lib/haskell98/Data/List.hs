-- Data.List: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module List
-- and the Prelude names the 2010 Report lists, plus what 2010 added.
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
    -- base, not the Report
    dropWhileEnd, sortOn, isSubsequenceOf, uncons, unsnoc, singleton,
    scanl', iterate', (!?)
  ) where

import List hiding (genericLength)

infixl 9 !?

dropWhileEnd :: (a -> Bool) -> [a] -> [a]
dropWhileEnd p = foldr (\x xs -> if p x && null xs then [] else x : xs) []

-- the key is computed once per element
sortOn :: Ord b => (a -> b) -> [a] -> [a]
sortOn f = map snd . sortBy (\a b -> compare (fst a) (fst b)) . map (\x -> let y = f x in y `seq` (y, x))

isSubsequenceOf :: Eq a => [a] -> [a] -> Bool
isSubsequenceOf [] _ = True
isSubsequenceOf _ [] = False
isSubsequenceOf a@(x:a') (y:b) | x == y = isSubsequenceOf a' b
                               | otherwise = isSubsequenceOf a b

uncons :: [a] -> Maybe (a, [a])
uncons [] = Nothing
uncons (x:xs) = Just (x, xs)

unsnoc :: [a] -> Maybe ([a], a)
unsnoc [] = Nothing
unsnoc xs = Just (init xs, last xs)

singleton :: a -> [a]
singleton x = [x]

scanl' :: (b -> a -> b) -> b -> [a] -> [b]
scanl' f q ls = q `seq` (q : case ls of
                               [] -> []
                               x:xs -> scanl' f (f q x) xs)

iterate' :: (a -> a) -> a -> [a]
iterate' f x = x `seq` (x : iterate' f (f x))

(!?) :: [a] -> Int -> Maybe a
xs !? n
  | n < 0 = Nothing
  | otherwise = case drop n xs of
                  (y:_) -> Just y
                  [] -> Nothing

intercalate :: [a] -> [[a]] -> [a]
intercalate xs xss = concat (intersperse xs xss)

-- A strict left fold: the accumulator is evaluated at each step.
foldl' :: (a -> b -> a) -> a -> [b] -> a
foldl' f z []     = z
foldl' f z (x:xs) = let z' = f z x in z' `seq` foldl' f z' xs

foldl1' :: (a -> a -> a) -> [a] -> a
foldl1' f (x:xs) = foldl' f x xs
foldl1' _ []     = error "Data.List.foldl1': empty list"

subsequences :: [a] -> [[a]]
subsequences xs = [] : nonEmptySubsequences xs
  where nonEmptySubsequences []     = []
        nonEmptySubsequences (y:ys) = [y] : foldr f [] (nonEmptySubsequences ys)
          where f zs r = zs : (y : zs) : r

-- In the order of the Report's reference code (and GHC's).
permutations :: [a] -> [[a]]
permutations xs0 = xs0 : perms xs0 []
  where
    perms []     _  = []
    perms (t:ts) is = foldr interleave (perms ts (t:is)) (permutations is)
      where interleave xs r = let (_, zs) = interleave' id xs r in zs
            interleave' _ [] r = (ts, r)
            interleave' f (y:ys) r = let (us, zs) = interleave' (f . (y:)) ys r
                                     in  (y:us, f (t:y:us) : zs)

stripPrefix :: Eq a => [a] -> [a] -> Maybe [a]
stripPrefix [] ys = Just ys
stripPrefix (x:xs) (y:ys) | x == y = stripPrefix xs ys
stripPrefix _ _ = Nothing

isInfixOf :: Eq a => [a] -> [a] -> Bool
isInfixOf needle haystack = any (isPrefixOf needle) (tails haystack)

-- | The length as any number (Haskell 2010's Num, not Haskell 98's
-- Integral: ListLike's genericLength = L.genericLength).
genericLength :: Num i => [a] -> i
genericLength = go 0
  where go n [] = n
        go n (_ : xs) = let n' = n + 1 in n' `seq` go n' xs
