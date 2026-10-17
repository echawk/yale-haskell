-- Data.Functor.Classes (base): equality, ordering, showing and reading
-- lifted to unary and binary type constructors.  Read1 and Read2 have
-- base's ReadS methods (liftReadsPrec, liftReadList), not its ReadPrec
-- ones (liftReadPrec), which Yale Haskell's Read class does not have.
module Data.Functor.Classes (
    Eq1(liftEq), eq1, Ord1(liftCompare), compare1,
    Show1(liftShowsPrec, liftShowList), showsPrec1,
    Read1(liftReadsPrec, liftReadList), readsPrec1,
    Eq2(liftEq2), eq2, Ord2(liftCompare2), compare2,
    Show2(liftShowsPrec2, liftShowList2), showsPrec2,
    Read2(liftReadsPrec2, liftReadList2), readsPrec2,
    readsData, readData, readsUnaryWith, readsUnary, readsUnary1,
    readsBinaryWith, readsBinary1,
    showsUnaryWith, showsUnary, showsUnary1, showsBinaryWith, showsBinary1
  ) where

import PreludeModern
import Data.Functor.Identity (Identity(Identity))
import Data.Functor.Const (Const(Const))
import Data.List.NonEmpty (NonEmpty((:|)))

class Eq1 f where
  liftEq :: (a -> b -> Bool) -> f a -> f b -> Bool

eq1 :: (Eq1 f, Eq a) => f a -> f a -> Bool
eq1 = liftEq (==)

class Eq1 f => Ord1 f where
  liftCompare :: (a -> b -> Ordering) -> f a -> f b -> Ordering

compare1 :: (Ord1 f, Ord a) => f a -> f a -> Ordering
compare1 = liftCompare compare

class Show1 f where
  liftShowsPrec :: (Int -> a -> ShowS) -> ([a] -> ShowS) -> Int -> f a -> ShowS
  liftShowList :: (Int -> a -> ShowS) -> ([a] -> ShowS) -> [f a] -> ShowS
  liftShowList sp sl = showListWith (liftShowsPrec sp sl 0)

showsPrec1 :: (Show1 f, Show a) => Int -> f a -> ShowS
showsPrec1 = liftShowsPrec showsPrec showList

class Read1 f where
  liftReadsPrec :: (Int -> ReadS a) -> ReadS [a] -> Int -> ReadS (f a)
  liftReadList :: (Int -> ReadS a) -> ReadS [a] -> ReadS [f a]
  liftReadList rp rl = readListWith (liftReadsPrec rp rl 0)

readsPrec1 :: (Read1 f, Read a) => Int -> ReadS (f a)
readsPrec1 = liftReadsPrec readsPrec readList

class Eq2 f where
  liftEq2 :: (a -> b -> Bool) -> (c -> d -> Bool) -> f a c -> f b d -> Bool

eq2 :: (Eq2 f, Eq a, Eq b) => f a b -> f a b -> Bool
eq2 = liftEq2 (==) (==)

class Eq2 f => Ord2 f where
  liftCompare2 :: (a -> b -> Ordering) -> (c -> d -> Ordering) -> f a c -> f b d -> Ordering

compare2 :: (Ord2 f, Ord a, Ord b) => f a b -> f a b -> Ordering
compare2 = liftCompare2 compare compare

class Show2 f where
  liftShowsPrec2 :: (Int -> a -> ShowS) -> ([a] -> ShowS) -> (Int -> b -> ShowS)
                 -> ([b] -> ShowS) -> Int -> f a b -> ShowS
  liftShowList2 :: (Int -> a -> ShowS) -> ([a] -> ShowS) -> (Int -> b -> ShowS)
                -> ([b] -> ShowS) -> [f a b] -> ShowS
  liftShowList2 sp1 sl1 sp2 sl2 = showListWith (liftShowsPrec2 sp1 sl1 sp2 sl2 0)

showsPrec2 :: (Show2 f, Show a, Show b) => Int -> f a b -> ShowS
showsPrec2 = liftShowsPrec2 showsPrec showList showsPrec showList

class Read2 f where
  liftReadsPrec2 :: (Int -> ReadS a) -> ReadS [a] -> (Int -> ReadS b) -> ReadS [b]
                 -> Int -> ReadS (f a b)
  liftReadList2 :: (Int -> ReadS a) -> ReadS [a] -> (Int -> ReadS b) -> ReadS [b]
                -> ReadS [f a b]
  liftReadList2 rp1 rl1 rp2 rl2 = readListWith (liftReadsPrec2 rp1 rl1 rp2 rl2 0)

readsPrec2 :: (Read2 f, Read a, Read b) => Int -> ReadS (f a b)
readsPrec2 = liftReadsPrec2 readsPrec readList readsPrec readList

-- the list syntax [x, y, ...], as the Prelude shows and reads lists
showListWith :: (a -> ShowS) -> [a] -> ShowS
showListWith _ [] s = "[]" ++ s
showListWith showx (x:xs) s = '[' : showx x (showl xs)
  where showl [] = ']' : s
        showl (y:ys) = ',' : showx y (showl ys)

readListWith :: ReadS a -> ReadS [a]
readListWith rx = readParen False (\r -> [pr | ("[", s) <- lex r, pr <- readl s])
  where readl s = [([], t) | ("]", t) <- lex s] ++
                  [(x : xs, u) | (x, t) <- rx s, (xs, u) <- readl' t]
        readl' s = [([], t) | ("]", t) <- lex s] ++
                   [(x : xs, v) | (",", t) <- lex s, (x, u) <- rx t, (xs, v) <- readl' u]

-- Building blocks for instances.

readsData :: (String -> ReadS a) -> Int -> ReadS a
readsData reader d = readParen (d > 10) (\r -> [res | (s, t) <- lex r, res <- reader s t])

readData :: (String -> ReadS a) -> Int -> ReadS a
readData = readsData

readsUnaryWith :: (Int -> ReadS a) -> String -> (a -> t) -> String -> ReadS t
readsUnaryWith rp name cons kw s = [(cons x, t) | kw == name, (x, t) <- rp 11 s]

readsUnary :: Read a => String -> (a -> t) -> String -> ReadS t
readsUnary = readsUnaryWith readsPrec

readsUnary1 :: (Read1 f, Read a) => String -> (f a -> t) -> String -> ReadS t
readsUnary1 = readsUnaryWith readsPrec1

readsBinaryWith :: (Int -> ReadS a) -> (Int -> ReadS b) -> String -> (a -> b -> t)
                -> String -> ReadS t
readsBinaryWith rp1 rp2 name cons kw s =
  [(cons x y, u) | kw == name, (x, t) <- rp1 11 s, (y, u) <- rp2 11 t]

readsBinary1 :: (Read1 f, Read1 g, Read a) => String -> (f a -> g a -> t) -> String -> ReadS t
readsBinary1 = readsBinaryWith readsPrec1 readsPrec1

showsUnaryWith :: (Int -> a -> ShowS) -> String -> Int -> a -> ShowS
showsUnaryWith sp name d x = showParen (d > 10) (showString name . showChar ' ' . sp 11 x)

showsUnary :: Show a => String -> Int -> a -> ShowS
showsUnary = showsUnaryWith showsPrec

showsUnary1 :: (Show1 f, Show a) => String -> Int -> f a -> ShowS
showsUnary1 = showsUnaryWith showsPrec1

showsBinaryWith :: (Int -> a -> ShowS) -> (Int -> b -> ShowS) -> String -> Int -> a -> b -> ShowS
showsBinaryWith sp1 sp2 name d x y =
  showParen (d > 10) (showString name . showChar ' ' . sp1 11 x . showChar ' ' . sp2 11 y)

showsBinary1 :: (Show1 f, Show1 g, Show a) => String -> Int -> f a -> g a -> ShowS
showsBinary1 = showsBinaryWith showsPrec1 showsPrec1

-- Instances.

instance Eq1 Maybe where
  liftEq _ Nothing Nothing = True
  liftEq eq (Just x) (Just y) = eq x y
  liftEq _ _ _ = False

instance Ord1 Maybe where
  liftCompare _ Nothing Nothing = EQ
  liftCompare _ Nothing (Just _) = LT
  liftCompare _ (Just _) Nothing = GT
  liftCompare cmp (Just x) (Just y) = cmp x y

instance Show1 Maybe where
  liftShowsPrec _ _ _ Nothing = showString "Nothing"
  liftShowsPrec sp _ d (Just x) = showsUnaryWith sp "Just" d x

instance Read1 Maybe where
  liftReadsPrec rp _ d =
    readParen False (\r -> [(Nothing, s) | ("Nothing", s) <- lex r]) `orElse`
    readsData (readsUnaryWith rp "Just" Just) d
    where orElse f g s = f s ++ g s

instance Eq1 [] where
  liftEq _ [] [] = True
  liftEq eq (x:xs) (y:ys) = eq x y && liftEq eq xs ys
  liftEq _ _ _ = False

instance Ord1 [] where
  liftCompare _ [] [] = EQ
  liftCompare _ [] (_:_) = LT
  liftCompare _ (_:_) [] = GT
  liftCompare cmp (x:xs) (y:ys) = cmp x y <> liftCompare cmp xs ys

instance Show1 [] where
  liftShowsPrec _ sl _ = sl

instance Read1 [] where
  liftReadsPrec _ rl _ = rl

instance Eq1 NonEmpty where
  liftEq eq (a :| as) (b :| bs) = eq a b && liftEq eq as bs

instance Ord1 NonEmpty where
  liftCompare cmp (a :| as) (b :| bs) = cmp a b <> liftCompare cmp as bs

instance Show1 NonEmpty where
  liftShowsPrec sp sl d (a :| as) =
    showParen (d > 5) (sp 6 a . showString " :| " . liftShowsPrec sp sl 6 as)

instance Eq1 Identity where
  liftEq eq (Identity x) (Identity y) = eq x y

instance Ord1 Identity where
  liftCompare cmp (Identity x) (Identity y) = cmp x y

instance Show1 Identity where
  liftShowsPrec sp _ d (Identity x) = showsUnaryWith sp "Identity" d x

instance Read1 Identity where
  liftReadsPrec rp _ = readsData (readsUnaryWith rp "Identity" Identity)

instance Eq a => Eq1 (Either a) where
  liftEq = liftEq2 (==)

instance Ord a => Ord1 (Either a) where
  liftCompare = liftCompare2 compare

instance Show a => Show1 (Either a) where
  liftShowsPrec = liftShowsPrec2 showsPrec showList

instance Read a => Read1 (Either a) where
  liftReadsPrec = liftReadsPrec2 readsPrec readList

instance Eq a => Eq1 ((,) a) where
  liftEq = liftEq2 (==)

instance Ord a => Ord1 ((,) a) where
  liftCompare = liftCompare2 compare

instance Show a => Show1 ((,) a) where
  liftShowsPrec = liftShowsPrec2 showsPrec showList

instance Read a => Read1 ((,) a) where
  liftReadsPrec = liftReadsPrec2 readsPrec readList

instance Eq a => Eq1 (Const a) where
  liftEq = liftEq2 (==)

instance Ord a => Ord1 (Const a) where
  liftCompare = liftCompare2 compare

instance Show a => Show1 (Const a) where
  liftShowsPrec = liftShowsPrec2 showsPrec showList

instance Eq2 Either where
  liftEq2 e1 _ (Left x) (Left y) = e1 x y
  liftEq2 _ e2 (Right x) (Right y) = e2 x y
  liftEq2 _ _ _ _ = False

instance Ord2 Either where
  liftCompare2 c1 _ (Left x) (Left y) = c1 x y
  liftCompare2 _ _ (Left _) (Right _) = LT
  liftCompare2 _ _ (Right _) (Left _) = GT
  liftCompare2 _ c2 (Right x) (Right y) = c2 x y

instance Show2 Either where
  liftShowsPrec2 sp1 _ _ _ d (Left x) = showsUnaryWith sp1 "Left" d x
  liftShowsPrec2 _ _ sp2 _ d (Right x) = showsUnaryWith sp2 "Right" d x

instance Read2 Either where
  liftReadsPrec2 rp1 _ rp2 _ d s =
    readsData (readsUnaryWith rp1 "Left" Left) d s ++
    readsData (readsUnaryWith rp2 "Right" Right) d s

instance Eq2 (,) where
  liftEq2 e1 e2 (x1, y1) (x2, y2) = e1 x1 x2 && e2 y1 y2

instance Ord2 (,) where
  liftCompare2 c1 c2 (x1, y1) (x2, y2) = c1 x1 x2 <> c2 y1 y2

instance Show2 (,) where
  liftShowsPrec2 sp1 _ sp2 _ _ (x, y) =
    showChar '(' . sp1 0 x . showChar ',' . sp2 0 y . showChar ')'

instance Read2 (,) where
  liftReadsPrec2 rp1 _ rp2 _ _ = readParen False (\r ->
    [((x, y), w) | ("(", s) <- lex r, (x, t) <- rp1 0 s, (",", u) <- lex t,
                   (y, v) <- rp2 0 u, (")", w) <- lex v])

instance Eq2 Const where
  liftEq2 eq _ (Const x) (Const y) = eq x y

instance Ord2 Const where
  liftCompare2 cmp _ (Const x) (Const y) = cmp x y

instance Show2 Const where
  liftShowsPrec2 sp _ _ _ d (Const x) = showsUnaryWith sp "Const" d x
