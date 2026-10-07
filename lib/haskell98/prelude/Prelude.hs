-- Standard value bindings
--
-- This module's symbol table is what user modules see as the Prelude
-- (the compiler copies it whole), so it only imports the names that
-- the Haskell 98 Prelude exports, plus the Yale extras listed below.
-- Everything else in the prelude modules is reached through the
-- libraries (List, Char, Numeric, Ratio, Complex, Ix, Array, ...).

module Prelude (
    PreludeCore.., PreludeList.., PreludeText..,
    -- I/O.  The Dialogue names (stdin ... prints) are Yale 1.2 compatibility.
    IOError, IO, FilePath(..), ioError, userError, catch,
    putChar, putStr, putStrLn, print, getChar, getLine, getContents,
    interact, readFile, writeFile, appendFile, readIO, readLn,
    stdin, stdout, stderr, stdecho, Dialogue(..), SuccCont(..), StrCont(..),
    StrListCont(..), FailCont(..), readChan, appendChan, done, exit, abort, prints,
    thenIO, thenIO_, seqIO, returnIO, doneIO, SystemState, IOResult,
    -- Not in the H98 Prelude (they are in Char), kept for compatibility:
    ord, chr, isAscii, isControl, isPrint, isSpace,
    isUpper, isLower, isAlpha, isDigit, isAlphaNum, toUpper, toLower,
    -- Haskell 1.2 names for minBound/maxBound, still used by Random:
    minInt, maxInt, minChar, maxChar, fromRealFrac,
    -- Yale's Binary class support (to be removed with Binary):
    nullBin, isNullBin, appendBin,
    (&&), (||), not, otherwise, maybe, either,
    subtract, gcd, lcm, (^), (^^), fromIntegral, realToFrac,
    fst, snd, curry, uncurry, id, const, (.), flip, ($), until,
    asTypeOf, error, undefined, seq, ($!) ) where

{-#Prelude#-}  -- Indicates definitions of compiler prelude symbols

import PreludePrims(error, primNullBin, primIsNullBin, primAppendBin)
import PreludeBltinArray(strict1)

import PreludeCore
import PreludeList(
    map, (++), filter, concat, concatMap,
    head, last, tail, init, null, length, (!!),
    foldl, foldl1, scanl, scanl1, foldr, foldr1, scanr, scanr1,
    iterate, repeat, replicate, cycle,
    take, drop, splitAt, takeWhile, dropWhile, span, break,
    lines, words, unlines, unwords, reverse, and, or,
    any, all, elem, notElem, lookup,
    sum, product, maximum, minimum,
    zip, zip3, zipWith, zipWith3, unzip, unzip3)
import PreludeText(reads, shows, show, read, lex,
		   showChar, showString, readParen, showParen)
import PreludeIO(IOError, IO, FilePath(..), ioError, userError, catch,
    putChar, putStr, putStrLn, print, getChar, getLine, getContents,
    interact, readFile, writeFile, appendFile, readIO, readLn,
    stdin, stdout, stderr, stdecho, Dialogue(..), SuccCont(..), StrCont(..),
    StrListCont(..), FailCont(..), readChan, appendChan, done, exit, abort, prints,
    thenIO, thenIO_, seqIO, returnIO, doneIO, SystemState, IOResult)
import PreludeChar(ord, chr, isAscii, isControl, isPrint, isSpace,
		   isUpper, isLower, isAlpha, isDigit, isAlphaNum,
		   toUpper, toLower, minChar, maxChar)

infixr 9  .
infixr 8  ^, ^^
infixr 3  &&
infixr 2  ||
infixr 0  $, $!, `seq`


-- Binary functions

nullBin	    	    	:: Bin
nullBin	    	    	=  primNullBin

isNullBin    	    	:: Bin -> Bool
isNullBin    	    	=  primIsNullBin

appendBin		:: Bin -> Bin -> Bin
appendBin		=  primAppendBin

-- Boolean functions

(&&), (||)		:: Bool -> Bool -> Bool
True  && x		=  x
False && _		=  False
True  || _		=  True
False || x		=  x

not			:: Bool -> Bool
not True		=  False
not False		=  True

{-# (&&)  :: Inline #-}
{-# (||)  :: Inline #-}
{-# not  :: Inline #-}


otherwise		:: Bool
otherwise 		=  True

-- Maybe and Either

maybe			:: b -> (a -> b) -> Maybe a -> b
maybe n f Nothing	=  n
maybe n f (Just x)	=  f x

either			:: (a -> c) -> (b -> c) -> Either a b -> c
either f g (Left x)	=  f x
either f g (Right y)	=  g y

-- Numeric functions

subtract	:: (Num a) => a -> a -> a
subtract	=  flip (-)

gcd		:: (Integral a) => a -> a -> a
gcd 0 0		=  error "Prelude.gcd: gcd 0 0 is undefined"
gcd x y		=  gcd' (abs x) (abs y)
		   where gcd' x 0  =  x
			 gcd' x y  =  gcd' y (x `rem` y)

lcm		:: (Integral a) => a -> a -> a
lcm _ 0		=  0
lcm 0 _		=  0
lcm x y		=  abs ((x `quot` (gcd x y)) * y)

(^)		:: (Num a, Integral b) => a -> b -> a
x ^ 0		=  1
x ^ n | n > 0	=  f x (n-1) x
		   where f _ 0 y = y
		         f x n y = g x n  where
			           g x n | even n  = g (x*x) (n `quot` 2)
				         | otherwise = f x (n-1) (x*y)
_ ^ _		= error "Prelude.^: negative exponent"

(^^)		:: (Fractional a, Integral b) => a -> b -> a
x ^^ n		=  if n >= 0 then x^n else recip (x^(-n))

fromIntegral	:: (Integral a, Num b) => a -> b
fromIntegral	=  fromInteger . toInteger

realToFrac	:: (Real a, Fractional b) => a -> b
realToFrac	=  fromRational . toRational

-- Haskell 1.2 name of realToFrac.
fromRealFrac	:: (Real a, Fractional b) => a -> b
fromRealFrac	=  realToFrac

-- Some standard functions:
-- component projections for pairs:
fst			:: (a,b) -> a
fst (x,y)		=  x

snd			:: (a,b) -> b
snd (x,y)		=  y

-- identity function
id			:: a -> a
id x			=  x

-- constant function
const			:: a -> b -> a
const x _		=  x

-- function composition
(.)			:: (b -> c) -> (a -> b) -> a -> c
f . g			=  \ x -> f (g x)

-- flip f  takes its (first) two arguments in the reverse order of f.
flip			:: (a -> b -> c) -> b -> a -> c
flip f x y		=  f y x

-- right-associating infix application operator (useful in continuation-
-- passing style)
($)			:: (a -> b) -> a -> b
f $ x			=  f x

-- until p f  yields the result of applying f until p holds.
until			:: (a -> Bool) -> (a -> a) -> a -> a
until p f x | p x	=  x
	    | otherwise =  until p f (f x)

-- asTypeOf is a type-restricted version of const.  It is usually used
-- as an infix operator, and its typing forces its first argument
-- (which is usually overloaded) to have the same type as the second.
asTypeOf		:: a -> a -> a
asTypeOf		=  const

-- curry converts an uncurried function to a curried function;
-- uncurry converts a curried function to a function on pairs.
curry			:: ((a, b) -> c) -> a -> b -> c
curry f x y		=  f (x, y)

uncurry			:: (a -> b -> c) -> ((a, b) -> c)
uncurry f p		=  f (fst p) (snd p)

undefined		:: a
undefined		=  error "Prelude.undefined"

-- Strict evaluation, via the strict1 primitive.
seq			:: a -> b -> b
seq x y			=  strict1 x y
{-# seq :: Inline #-}

($!)			:: (a -> b) -> a -> b
f $! x			=  x `seq` f x
{-# ($!) :: Inline #-}
