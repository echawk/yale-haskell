-- Standard types, classes, and instances

module PreludeCore (
    Eq((==), (/=)),
    Ord((<), (<=), (>=), (>), max, min, compare),
    Bounded(minBound, maxBound),
    Num((+), (-), (*), negate, abs, signum, fromInteger),
    Integral(quot, rem, div, mod, quotRem, divMod, even, odd, toInteger),
    Fractional((/), recip, fromRational),
    Floating(pi, exp, log, sqrt, (**), logBase,
	     sin, cos, tan, asin, acos, atan,
	     sinh, cosh, tanh, asinh, acosh, atanh),
    Real(toRational),
    RealFrac(properFraction, truncate, round, ceiling, floor),
    RealFloat(floatRadix, floatDigits, floatRange,
	      encodeFloat, decodeFloat, exponent, significand, scaleFloat,
	      isNaN, isInfinite, isDenormalized, isNegativeZero, isIEEE,
	      atan2),
    Ix(range, index, inRange),
    Enum(succ, pred, toEnum, fromEnum,
	 enumFrom, enumFromThen, enumFromTo, enumFromThenTo),
    Show(showsPrec, show, showList), Read(readsPrec, readList),
    ReadS(..), ShowS(..),
--  List type: [_]((:), [])
--  Tuple types: (_,_), (_,_,_), etc.
--  Trivial type: () 
    Bool(True, False),
    Ordering(LT, EQ, GT), Maybe(Nothing, Just), Either(Left, Right),
    Functor(fmap), Monad((>>=), (>>), return, fail),
    mapM, mapM_, sequence, sequence_, (=<<),
    Char, Int, Integer, Float, Double,
    Ratio, Complex((:+)), Assoc((:=)), Array,
    String(..), Rational(..) )  where

{-#Prelude#-}  -- Indicates definitions of compiler prelude symbols

import PreludePrims
import PreludeText
import PreludeNumeric(readSigned, readSignedDec, showSigned, readDec, showInt,
		      readFloat, showFloat)
import PreludeChar(ord, chr, minChar, maxChar)
import PreludeRatio(Ratio, Rational(..), (%))
import PreludeComplex(Complex((:+)))
import PreludeArray(Assoc((:=)), Array, listArray, bounds, elems)
import PreludeList(map, concatMap)

infixr 8  **
infixl 7  *, /, `quot`, `rem`, `div`, `mod`
infixl 6  +, -
infix  4  ==, /=, <, <=, >=, >


infixr 5 :
infixl 1 >>, >>=
infixr 1 =<<

data Int = MkInt
data Integer = MkInteger
data Float = MkFloat
data Double   = MkDouble
data Char = MkChar
-- The constructor order is fixed by the code generator (cons = 0), so a
-- derived Ord would put [] after every non-empty list; Ord is written
-- out below instead.
data List a = a : (List a) | Nil deriving (Eq)
data Arrow a b = MkArrow a b
data UnitType = UnitConstructor deriving (Eq, Ord, Ix)

-- Equality and Ordered classes

class  Eq a  where
    (==), (/=)		:: a -> a -> Bool

    x /= y		=  not (x == y)
    x == y		=  not (x /= y)

-- compare is the last method because the runtime builds tuple dictionaries
-- from the method order (src/runtime/tuple-prims.mumble).  Minimal complete
-- definition: compare or (<=).
class  (Eq a) => Ord a  where
    (<), (<=), (>=), (>):: a -> a -> Bool
    max, min		:: a -> a -> a
    compare		:: a -> a -> Ordering

    compare x y | x == y	=  EQ
		| x <= y	=  LT
		| otherwise	=  GT
    x <	 y		=  case compare x y of { LT -> True;  _ -> False }
    x <= y		=  case compare x y of { GT -> False; _ -> True }
    x >	 y		=  case compare x y of { GT -> True;  _ -> False }
    x >= y		=  case compare x y of { LT -> False; _ -> True }

    -- Haskell 98 defaults (total orders).
    max x y | x <= y	=  y
	    | otherwise	=  x
    min x y | x <= y	=  x
	    | otherwise	=  y

data  Ordering  =  LT | EQ | GT  deriving (Eq, Ord, Ix)


-- Bounded class (H98).

class  Bounded a  where
    minBound, maxBound	:: a


-- Numeric classes

class  (Eq a, Show a) => Num a  where
    (+), (-), (*)	:: a -> a -> a
    negate		:: a -> a
    abs, signum		:: a -> a
    fromInteger		:: Integer -> a

    x - y		=  x + negate y

class  (Num a, Ord a) => Real a  where
    toRational		::  a -> Rational

class  (Real a, Enum a) => Integral a  where
    quot, rem, div, mod	:: a -> a -> a
    quotRem, divMod	:: a -> a -> (a,a)
    even, odd		:: a -> Bool
    toInteger		:: a -> Integer

    n `quot` d		=  q  where (q,r) = quotRem n d
    n `rem` d		=  r  where (q,r) = quotRem n d
    n `div` d		=  q  where (q,r) = divMod n d
    n `mod` d		=  r  where (q,r) = divMod n d
    divMod n d 		=  if signum r == - signum d then (q-1, r+d) else qr
			   where qr@(q,r) = quotRem n d
    even n		=  n `rem` 2 == 0
    odd			=  not . even

class  (Num a) => Fractional a  where
    (/)			:: a -> a -> a
    recip		:: a -> a
    fromRational	:: Rational -> a

    recip x		=  1 / x

class  (Fractional a) => Floating a  where
    pi			:: a
    exp, log, sqrt	:: a -> a
    (**), logBase	:: a -> a -> a
    sin, cos, tan	:: a -> a
    asin, acos, atan	:: a -> a
    sinh, cosh, tanh	:: a -> a
    asinh, acosh, atanh :: a -> a

    x ** y		=  exp (log x * y)
    logBase x y		=  log y / log x
    sqrt x		=  x ** 0.5
    tan  x		=  sin  x / cos  x
    tanh x		=  sinh x / cosh x

class  (Real a, Fractional a) => RealFrac a  where
    properFraction	:: (Integral b) => a -> (b,a)
    truncate, round	:: (Integral b) => a -> b
    ceiling, floor	:: (Integral b) => a -> b

    truncate x		=  m  where (m,_) = properFraction x
    
    round x		=  let (n,r) = properFraction x
    			       m     = if r < 0 then n - 1 else n + 1
    			   in case signum (abs r - 0.5) of
    				-1 -> n
    			 	0  -> if even n then n else m
    				1  -> m
    
    ceiling x		=  if r > 0 then n + 1 else n
    			   where (n,r) = properFraction x
    
    floor x		=  if r < 0 then n - 1 else n
    			   where (n,r) = properFraction x

class  (RealFrac a, Floating a) => RealFloat a  where
    floatRadix		:: a -> Integer
    floatDigits		:: a -> Int
    floatRange		:: a -> (Int,Int)
    decodeFloat		:: a -> (Integer,Int)
    encodeFloat		:: Integer -> Int -> a
    exponent		:: a -> Int
    significand		:: a -> a
    scaleFloat		:: Int -> a -> a
    isNaN, isInfinite, isDenormalized, isNegativeZero, isIEEE
			:: a -> Bool
    atan2		:: a -> a -> a

    exponent x		=  if m == 0 then 0 else n + floatDigits x
			   where (m,n) = decodeFloat x

    significand x	=  encodeFloat m (- floatDigits x)
			   where (m,_) = decodeFloat x

    scaleFloat k x	=  encodeFloat m (n+k)
			   where (m,n) = decodeFloat x

    -- The IEEE predicates are computed with comparisons only, since the
    -- runtime has no float primitives for them and SBCL traps on
    -- overflow and division by zero.
    isNaN x		=  x /= x
    isInfinite x	=  not (isNaN x) && abs x > maxFinite
			   where maxFinite = encodeFloat (floatRadix x ^ d - 1)
							 (snd (floatRange x) - d)
				 d = floatDigits x
    isDenormalized x	=  x /= 0 && abs x < minNormal
			   where minNormal = encodeFloat 1 (fst (floatRange x) - 1)
    isNegativeZero x	=  False
    isIEEE x		=  True

    atan2 y x
      | x > 0		=  atan (y/x)
      | x == 0 && y > 0	=  pi/2
      | x <  0 && y > 0	=  pi + atan (y/x)
      | (x <= 0 && y < 0) ||
	(x <  0 && isNegativeZero y) ||
	(isNegativeZero x && isNegativeZero y)
			= - atan2 (-y) x
      | y == 0 && (x < 0 || isNegativeZero x)
			=  pi	-- must be after the previous test on zero y
      | x == 0 && y == 0	=  y	-- must be after the other double zero tests
      | otherwise	=  x + y -- x or y is a NaN, return a NaN (via +)


-- Index and Enumeration classes

class  (Ord a) => Ix a  where
    range		:: (a,a) -> [a]
    index		:: (a,a) -> a -> Int
    inRange		:: (a,a) -> a -> Bool

-- H98: Enum has no Ord superclass.  The defaults for enumFromTo and
-- enumFromThenTo go through Int, as in the Report; instances for types
-- with an ordering (Int, Integer, Char) use defaultEnumFromTo below.

class  Enum a	where
    succ, pred		:: a -> a
    toEnum		:: Int -> a
    fromEnum		:: a -> Int
    enumFrom		:: a -> [a]		-- [n..]
    enumFromThen	:: a -> a -> [a]	-- [n,n'..]
    enumFromTo		:: a -> a -> [a]	-- [n..m]
    enumFromThenTo	:: a -> a -> a -> [a]	-- [n,n'..m]

    succ x		= case enumFrom x of
			    (_:y:_) -> y
			    _       -> error "succ{PreludeCore}: bad argument"
    pred		= toEnum . (subtract 1) . fromEnum
    toEnum _		= error "toEnum{PreludeCore}: not defined for this type"
    fromEnum _		= error "fromEnum{PreludeCore}: not defined for this type"
    enumFrom x		= map toEnum [fromEnum x ..]
    enumFromThen x y	= map toEnum [fromEnum x, fromEnum y ..]
    enumFromTo x y	= map toEnum [fromEnum x .. fromEnum y]
    enumFromThenTo x y z
			= map toEnum [fromEnum x, fromEnum y .. fromEnum z]

defaultEnumFromTo n m	=  takeWhile (<= m) (enumFrom n)
defaultEnumFromThenTo n n' m
			=  takeWhile (if n' >= n then (<= m) else (>= m))
				     (enumFromThen n n')
{-# defaultEnumFromTo :: Inline #-}
{-# defaultEnumFromThenTo :: Inline #-}

-- Show and Read classes.  The method order is the dictionary layout the
-- runtime builds for tuples (src/runtime/tuple-prims.mumble).

type  ReadS a = String -> [(a,String)]
type  ShowS   = String -> String

class  Show a  where
    showsPrec :: Int -> a -> ShowS
    show      :: a -> String
    showList  :: [a] -> ShowS

    showsPrec _ x s = show x ++ s
    show x	= showsPrec 0 x ""
    showList []	= showString "[]"
    showList (x:xs)
		= showChar '[' . shows x . showl xs
		  where showl []     = showChar ']'
			showl (x:xs) = showChar ',' . shows x . showl xs

class  Read a  where
    readsPrec :: Int -> ReadS a
    readList  :: ReadS [a]

    readList    = readParen False (\r -> [pr | ("[",s)	<- lex r,
					       pr	<- readl s])
	          where readl  s = [([],t)   | ("]",t)  <- lex s] ++
				   [(x:xs,u) | (x,t)    <- reads s,
					       (xs,u)   <- readl' t]
			readl' s = [([],t)   | ("]",t)  <- lex s] ++
			           [(x:xs,v) | (",",t)  <- lex s,
					       (x,u)	<- reads t,
					       (xs,v)   <- readl' u]


-- Maybe and Either (H98).  The Show and Read instances are written out to get
-- the H98 output format.

data  Maybe a  =  Nothing | Just a	deriving (Eq, Ord)

instance  (Show a) => Show (Maybe a)  where
    showsPrec d Nothing  = showString "Nothing"
    showsPrec d (Just x) = showParen (d > 10)
			     (showString "Just " . showsPrec 11 x)

instance  (Read a) => Read (Maybe a)  where
    readsPrec d r =  readParen False
			(\r -> [(Nothing,s) | ("Nothing",s) <- lex r]) r
		  ++ readParen (d > 10)
			(\r -> [(Just x,t) | ("Just",s) <- lex r,
					     (x,t)	<- readsPrec 11 s]) r

data  Either a b  =  Left a | Right b	deriving (Eq, Ord)

instance  (Show a, Show b) => Show (Either a b)  where
    showsPrec d (Left x)  = showParen (d > 10)
			      (showString "Left " . showsPrec 11 x)
    showsPrec d (Right x) = showParen (d > 10)
			      (showString "Right " . showsPrec 11 x)

instance  (Read a, Read b) => Read (Either a b)  where
    readsPrec d r =  readParen (d > 10)
			(\r -> [(Left x,t) | ("Left",s) <- lex r,
					     (x,t)	<- readsPrec 11 s]) r
		  ++ readParen (d > 10)
			(\r -> [(Right x,t) | ("Right",s) <- lex r,
					      (x,t)	 <- readsPrec 11 s]) r

-- Constructor classes (H98): Functor and Monad, with the instances the
-- Prelude gives for lists and Maybe.  The IO instance is in PreludeIO.

class  Functor f  where
    fmap		:: (a -> b) -> f a -> f b

class  Monad m  where
    (>>=)		:: m a -> (a -> m b) -> m b
    (>>)		:: m a -> m b -> m b
    return		:: a -> m a
    fail		:: String -> m a

    m >> k		=  m >>= \_ -> k
    fail s		=  error s

instance  Functor []  where
    fmap		=  map

instance  Monad []  where
    m >>= k		=  concatMap k m
    return x		=  [x]
    fail s		=  []

mapM			:: Monad m => (a -> m b) -> [a] -> m [b]
mapM f []		=  return []
mapM f (x:xs)		=  f x >>= \y -> mapM f xs >>= \ys -> return (y:ys)

mapM_			:: Monad m => (a -> m b) -> [a] -> m ()
mapM_ f []		=  return ()
mapM_ f (x:xs)		=  f x >> mapM_ f xs

sequence		:: Monad m => [m a] -> m [a]
sequence []		=  return []
sequence (c:cs)		=  c >>= \x -> sequence cs >>= \xs -> return (x:xs)

sequence_		:: Monad m => [m a] -> m ()
sequence_ []		=  return ()
sequence_ (c:cs)	=  c >> sequence_ cs

(=<<)			:: Monad m => (a -> m b) -> m a -> m b
f =<< x			=  x >>= f

instance  Functor Maybe  where
    fmap f Nothing	=  Nothing
    fmap f (Just x)	=  Just (f x)

instance  Monad Maybe  where
    (Just x) >>= k	=  k x
    Nothing  >>= k	=  Nothing
    return		=  Just
    fail s		=  Nothing

-- Trivial type

-- data  ()  =  ()  deriving (Eq, Ord, Ix, Enum, Bounded)

instance  Show ()  where
    showsPrec p () = showString "()"

instance  Read ()  where
    readsPrec p    = readParen False
    	    	    	    (\r -> [((),t) | ("(",s) <- lex r,
					     (")",t) <- lex s ] )

instance  Enum ()  where
    succ _		=  error "succ{PreludeCore}: bad argument"
    pred _		=  error "pred{PreludeCore}: bad argument"
    toEnum 0		=  ()
    toEnum _		=  error "toEnum{PreludeCore}: bad argument"
    fromEnum ()		=  0
    enumFrom ()		=  [()]
    enumFromThen () ()	=  repeat ()
    enumFromTo () ()	=  [()]
    enumFromThenTo () () () = repeat ()

instance  Bounded ()  where
    minBound		=  ()
    maxBound		=  ()



-- Boolean type

data  Bool  =  False | True	deriving (Eq, Ord, Ix, Show, Read)

-- Enum Bool and Enum Ordering are written out because derived Enum
-- instances do not define toEnum and fromEnum.

instance  Enum Bool  where
    succ False		=  True
    succ True		=  error "succ{PreludeCore}: bad argument"
    pred True		=  False
    pred False		=  error "pred{PreludeCore}: bad argument"
    toEnum 0		=  False
    toEnum 1		=  True
    toEnum _		=  error "toEnum{PreludeCore}: bad argument"
    fromEnum False	=  0
    fromEnum True	=  1
    enumFrom x		=  enumFromTo x True
    enumFromThen x y	=  enumFromThenTo x y (if fromEnum y >= fromEnum x
						  then True else False)
    enumFromTo x y	=  map toEnum [fromEnum x .. fromEnum y]
    enumFromThenTo x y z =  map toEnum [fromEnum x, fromEnum y .. fromEnum z]

instance  Bounded Bool  where
    minBound		=  False
    maxBound		=  True

-- Ordering type (H98)

instance  Enum Ordering  where
    succ LT		=  EQ
    succ EQ		=  GT
    succ GT		=  error "succ{PreludeCore}: bad argument"
    pred GT		=  EQ
    pred EQ		=  LT
    pred LT		=  error "pred{PreludeCore}: bad argument"
    toEnum 0		=  LT
    toEnum 1		=  EQ
    toEnum 2		=  GT
    toEnum _		=  error "toEnum{PreludeCore}: bad argument"
    fromEnum LT		=  0
    fromEnum EQ		=  1
    fromEnum GT		=  2
    enumFrom x		=  enumFromTo x GT
    enumFromThen x y	=  enumFromThenTo x y (if fromEnum y >= fromEnum x
						  then GT else LT)
    enumFromTo x y	=  map toEnum [fromEnum x .. fromEnum y]
    enumFromThenTo x y z =  map toEnum [fromEnum x, fromEnum y .. fromEnum z]

instance  Bounded Ordering  where
    minBound		=  LT
    maxBound		=  GT

instance  Show Ordering  where
    showsPrec p LT	=  showString "LT"
    showsPrec p EQ	=  showString "EQ"
    showsPrec p GT	=  showString "GT"

instance  Read Ordering  where
    readsPrec p r	=  [(LT,s) | ("LT",s) <- lex r] ++
			   [(EQ,s) | ("EQ",s) <- lex r] ++
			   [(GT,s) | ("GT",s) <- lex r]


-- Character type

instance  Eq Char  where
    (==)		=  primEqChar
    (/=)                =  primNeqChar

instance  Ord Char  where
    (<)                 =  primLsChar
    (<=)		=  primLeChar
    (>)                 =  primGtChar
    (>=)                =  primGeChar

instance  Ix Char  where
    range (c,c')	=  [c..c']
    index b@(c,c') ci
	| inRange b ci	=  ord ci - ord c
	| otherwise	=  error "index{PreludeCore}: Index out of range."
    inRange (c,c') ci	=  ord c <= i && i <= ord c'
			   where i = ord ci
    {-# range :: Inline #-}

instance  Enum Char  where
    succ c		= if c == maxChar
			    then error "succ{PreludeCore}: bad argument"
			    else chr (ord c + 1)
    pred c		= if c == minChar
			    then error "pred{PreludeCore}: bad argument"
			    else chr (ord c - 1)
    toEnum		= chr
    fromEnum		= ord
    enumFrom		= charEnumFrom
    enumFromThen        = charEnumFromThen
    enumFromTo          = defaultEnumFromTo
    enumFromThenTo      = defaultEnumFromThenTo
    {-# enumFrom :: Inline #-}
    {-# enumFromThen :: Inline #-}
    {-# enumFromTo :: Inline #-}
    {-# enumFromThenTo :: Inline #-}

instance  Bounded Char  where
    minBound		=  minChar
    maxBound		=  maxChar

charEnumFrom c		=  map chr [ord c .. ord maxChar]
charEnumFromThen c c'	=  map chr [ord c, ord c' .. ord lastChar]
			   where lastChar = if c' < c then minChar else maxChar
{-# charEnumFrom :: Inline #-}
{-# charEnumFromThen :: Inline #-}

instance  Show Char  where
    showsPrec p '\'' = showString "'\\''"
    showsPrec p c    = showChar '\'' . showLitChar c . showChar '\''

    showList cs = showChar '"' . showl cs
		 where showl ""       = showChar '"'
		       showl ('"':cs) = showString "\\\"" . showl cs
		       showl (c:cs)   = showLitChar c . showl cs

instance  Read Char  where
    readsPrec p      = readParen False
    	    	    	    (\r -> [(c,t) | ('\'':s,t)<- lex r,
					    (c,_)     <- readLitChar s])

    readList = readParen False (\r -> [(l,t) | ('"':s, t) <- lex r,
					       (l,_)      <- readl s ])
	       where readl ('"':s)	= [("",s)]
		     readl ('\\':'&':s)	= readl s
		     readl s		= [(c:cs,u) | (c ,t) <- readLitChar s,
						      (cs,u) <- readl t	      ]

type  String = [Char]


-- Standard Integral types

instance  Eq Int  where
    (==)		=  primEqInt
    (/=)                =  primNeqInt

instance  Eq Integer  where
    (==)		=  primEqInteger
    (/=)                =  primNeqInteger

instance  Ord Int  where
    (<)                 =  primLsInt
    (<=)		=  primLeInt
    (>)                 =  primGtInt
    (>=)                =  primGeInt
    max                 =  primIntMax
    min                 =  primIntMin

instance  Ord Integer  where
    (<)                 =  primLsInteger
    (<=)		=  primLeInteger
    (>)                 =  primGtInteger
    (>=)                =  primGeInteger
    max                 =  primIntegerMax
    min                 =  primIntegerMin

instance  Num Int  where
    (+)			=  primPlusInt
    (-)                 =  primMinusInt
    negate		=  primNegInt
    (*)			=  primMulInt
    abs			=  primAbsInt
    signum		=  signumReal
    fromInteger		=  primIntegerToInt

instance  Num Integer  where
    (+)			=  primPlusInteger
    (-)                 =  primMinusInteger
    negate		=  primNegInteger
    (*)			=  primMulInteger
    abs			=  primAbsInteger
    signum		=  signumReal
    fromInteger x	=  x
    
signumReal x | x == 0	 =  0
   	     | x > 0	 =  1
	     | otherwise = -1

instance  Real Int  where
    toRational x	=  toInteger x % 1

instance  Real Integer	where
    toRational x	=  x % 1

instance  Integral Int	where
    quot		=  primQuotInt
    rem			=  primRemInt
    div			=  primDivInt
    mod			=  primModInt
    quotRem		=  primQuotRemInt
    divMod		=  primDivModInt
    even		=  primEvenInt
    odd			=  primOddInt
    toInteger		=  primIntToInteger

instance  Integral Integer  where
    quot		=  primQuotInteger
    rem			=  primRemInteger
    div			=  primDivInteger
    mod			=  primModInteger
    quotRem		=  primQuotRemInteger
    divMod		=  primDivModInteger
    even		=  primEvenInteger
    odd			=  primOddInteger
    toInteger x		=  x

instance  Ix Int  where
    range (m,n)		=  [m..n]
    index b@(m,n) i
	| inRange b i	=  i - m
	| otherwise	=  error "index{PreludeCore}: Index out of range."
    inRange (m,n) i	=  m <= i && i <= n
    {-# range :: Inline #-}

instance  Ix Integer  where
    range (m,n)		=  [m..n]
    index b@(m,n) i
	| inRange b i	=  fromInteger (i - m)
	| otherwise	=  error "index{PreludeCore}: Index out of range."
    inRange (m,n) i	=  m <= i && i <= n
    {-# range :: Inline #-}

instance  Enum Int  where
    succ x		=  if x == maxInt
			     then error "succ{PreludeCore}: bad argument"
			     else x + 1
    pred x		=  if x == minInt
			     then error "pred{PreludeCore}: bad argument"
			     else x - 1
    toEnum x		=  x
    fromEnum x		=  x
    enumFrom		=  numericEnumFrom
    enumFromThen	=  numericEnumFromThen
    enumFromTo          = defaultEnumFromTo
    enumFromThenTo      = defaultEnumFromThenTo
    {-# enumFrom :: Inline #-}
    {-# enumFromThen :: Inline #-}
    {-# enumFromTo :: Inline #-}
    {-# enumFromThenTo :: Inline #-}

instance  Bounded Int  where
    minBound		=  minInt
    maxBound		=  maxInt

instance  Enum Integer  where
    succ x		=  x + 1
    pred x		=  x - 1
    toEnum x		=  primIntToInteger x
    fromEnum x		=  primIntegerToInt x
    enumFrom		=  numericEnumFrom
    enumFromThen	=  numericEnumFromThen
    enumFromTo          = defaultEnumFromTo
    enumFromThenTo      = defaultEnumFromThenTo
    {-# enumFrom :: Inline #-}
    {-# enumFromThen :: Inline #-}
    {-# enumFromTo :: Inline #-}
    {-# enumFromThenTo :: Inline #-}

numericEnumFrom		:: (Real a) => a -> [a]
numericEnumFromThen	:: (Real a) => a -> a -> [a]
numericEnumFrom		=  iterate (+1)
numericEnumFromThen n m	=  iterate (+(m-n)) n

{-# numericEnumFrom :: Inline #-}
{-# numericEnumFromThen :: Inline #-}

-- H98 semantics for Fractional enumerations: go half a step past the
-- limit.
numericEnumFromTo	:: (Real a, Fractional a) => a -> a -> [a]
numericEnumFromTo n m	=  takeWhile (<= m + 1/2) (numericEnumFrom n)

numericEnumFromThenTo	:: (Real a, Fractional a) => a -> a -> a -> [a]
numericEnumFromThenTo e1 e2 e3
			=  takeWhile p (numericEnumFromThen e1 e2)
			   where mid = (e2 - e1) / 2
				 p | e2 >= e1  = (<= e3 + mid)
				   | otherwise = (>= e3 + mid)


-- Show Int and Integer print with Lisp (much faster than digit by digit
-- for big Integers); showSigned's parentheses are kept.
instance  Show Int  where
    showsPrec p n r
	| n < 0 && p > 6	= '(' : primShowsInt n (')' : r)
	| otherwise		= primShowsInt n r

instance  Read Int  where
    readsPrec p		= readSignedDec

minInt, maxInt	:: Int
minInt		=  primMinInt
maxInt		=  primMaxInt

instance  Show Integer  where
    showsPrec p n r
	| n < 0 && p > 6	= '(' : primShowsInteger n (')' : r)
	| otherwise		= primShowsInteger n r

instance  Read Integer  where
    readsPrec p 	= readSignedDec


-- Standard Floating types

instance  Eq Float  where
    (==)		=  primEqFloat
    (/=)                =  primNeqFloat

instance  Eq Double  where
    (==)		=  primEqDouble
    (/=)                =  primNeqDouble

instance  Ord Float  where
    (<)                 =  primLsFloat
    (<=)		=  primLeFloat
    (>)                 =  primGtFloat
    (>=)                =  primGeFloat
    max                 =  primFloatMax
    min                 =  primFloatMin

instance  Ord Double  where
    (<)                 =  primLsDouble
    (<=)		=  primLeDouble
    (>)                 =  primGtDouble
    (>=)                =  primGeDouble
    max                 =  primDoubleMax
    min                 =  primDoubleMin

instance  Num Float  where
    (+)			=  primPlusFloat
    (-)                 =  primMinusFloat
    negate		=  primNegFloat
    (*)			=  primMulFloat
    abs			=  primAbsFloat
    signum		=  signumReal
    fromInteger n	=  encodeFloat n 0

instance  Num Double  where
    (+)			=  primPlusDouble
    (-)                 =  primMinusDouble
    negate		=  primNegDouble
    (*)			=  primMulDouble
    abs			=  primAbsDouble
    signum		=  signumReal
    fromInteger n	=  encodeFloat n 0

instance  Real Float  where
    toRational		=  primFloatToRational

instance  Real Double  where
    toRational		=  primDoubleToRational

-- realFloatToRational x	=  (m%1)*(b%1)^^n
--	 		   where (m,n) = decodeFloat x
-- 				 b     = floatRadix  x

instance  Fractional Float  where
    (/)			=  primDivFloat
    fromRational        =  primRationalToFloat
--    fromRational	=  rationalToRealFloat

instance  Fractional Double  where
    (/)			=  primDivDouble
    fromRational        =  primRationalToDouble
--    fromRational	=  rationalToRealFloat

-- rationalToRealFloat x	= x'
--         where x'    = f e
--               f e   = if e' == e then y else f e'
--                       where y      = encodeFloat (round (x * (1%b)^^e)) e
--                             (_,e') = decodeFloat y
--               (_,e) = decodeFloat (fromInteger (numerator x) `asTypeOf` x'
--                                         / fromInteger (denominator x))
--               b     = floatRadix x'

instance  Floating Float  where
    pi			=  primPiFloat
    exp			=  primExpFloat
    log			=  primLogFloat
    sqrt		=  primSqrtFloat
    (**)		=  primPowFloat
    sin			=  primSinFloat
    cos			=  primCosFloat
    tan			=  primTanFloat
    asin		=  primAsinFloat
    acos		=  primAcosFloat
    atan		=  primAtanFloat
    sinh		=  primSinhFloat
    cosh		=  primCoshFloat
    tanh		=  primTanhFloat
    asinh		=  primAsinhFloat
    acosh		=  primAcoshFloat
    atanh		=  primAtanhFloat

instance  Floating Double  where
    pi			=  primPiDouble
    exp			=  primExpDouble
    log			=  primLogDouble
    sqrt		=  primSqrtDouble
    (**)		=  primPowDouble
    sin			=  primSinDouble
    cos			=  primCosDouble
    tan			=  primTanDouble
    asin		=  primAsinDouble
    acos		=  primAcosDouble
    atan		=  primAtanDouble
    sinh		=  primSinhDouble
    cosh		=  primCoshDouble
    tanh		=  primTanhDouble
    asinh		=  primAsinhDouble
    acosh		=  primAcoshDouble
    atanh		=  primAtanhDouble


instance  RealFrac Float  where
    properFraction	=  floatProperFraction

instance  RealFrac Double  where
    properFraction	=  floatProperFraction

floatProperFraction x
	| n >= 0	=  (fromInteger m * fromInteger b ^ n, 0)
	| otherwise	=  (fromInteger w, encodeFloat r n)
			where (m,n) = decodeFloat x
			      b     = floatRadix x
			      (w,r) = quotRem m (b^(-n))

instance  RealFloat Float  where
    floatRadix _	=  primFloatRadix
    floatDigits _	=  primFloatDigits
    floatRange _	=  (primFloatMinExp + primFloatDigits - 1, primFloatMaxExp)
    decodeFloat		=  primDecodeFloat
    encodeFloat		=  primEncodeFloat
    isNegativeZero x	=  x == 0 && primFloatSignFloat x < 0

instance  RealFloat Double  where
    floatRadix _	=  primDoubleRadix
    floatDigits	_	=  primDoubleDigits
    floatRange _	=  (primDoubleMinExp + primDoubleDigits - 1, primDoubleMaxExp)
    decodeFloat		=  primDecodeDouble
    encodeFloat		=  primEncodeDouble
    isNegativeZero x	=  x == 0 && primFloatSignDouble x < 0

instance  Enum Float  where
    succ x		=  x + 1
    pred x		=  x - 1
    toEnum		=  fromIntegral
    fromEnum		=  truncate
    enumFrom		=  numericEnumFrom
    enumFromThen	=  numericEnumFromThen
    enumFromTo          =  numericEnumFromTo
    enumFromThenTo      =  numericEnumFromThenTo
    {-# enumFrom :: Inline #-}
    {-# enumFromThen :: Inline #-}
    {-# enumFromTo :: Inline #-}
    {-# enumFromThenTo :: Inline #-}

instance  Enum Double  where
    succ x		=  x + 1
    pred x		=  x - 1
    toEnum		=  fromIntegral
    fromEnum		=  truncate
    enumFrom		=  numericEnumFrom
    enumFromThen	=  numericEnumFromThen
    enumFromTo          =  numericEnumFromTo
    enumFromThenTo      =  numericEnumFromThenTo
    {-# enumFrom :: Inline #-}
    {-# enumFromThen :: Inline #-}
    {-# enumFromTo :: Inline #-}
    {-# enumFromThenTo :: Inline #-}

instance  Show Float  where
    showsPrec		= showSignedFloat

instance  Read Float  where
    readsPrec p		= readSigned readFloat

instance  Show Double  where
    showsPrec		= showSignedFloat

instance  Read Double  where
    readsPrec p		= readSigned readFloat


showSignedFloat		:: (RealFloat a) => Int -> a -> ShowS
showSignedFloat p x
	| x < 0 || isNegativeZero x
			= showParen (p > 6) (showChar '-' . showFloat (-x))
	| otherwise	= showFloat x

-- Lists

-- data  [a]  =  [] | a : [a]  deriving (Eq, Ord)

instance  (Ord a) => Ord [a]  where
    []     <= _	=  True
    (_:_)  <= []	=  False
    (x:xs) <= (y:ys)	=  x < y || (x == y && xs <= ys)
    []     <  []	=  False
    []     <  (_:_)	=  True
    (_:_)  <  []	=  False
    (x:xs) <  (y:ys)	=  x < y || (x == y && xs < ys)

instance  (Show a) => Show [a]  where
    showsPrec p		= showList

instance  (Read a) => Read [a]  where
    readsPrec p		= readList


-- Tuples

-- Tuple instances of Eq, Ord, Ix, Bounded, Show and Read are built by the
-- runtime for every arity (src/runtime/tuple-prims.mumble, PreludeTuple).
