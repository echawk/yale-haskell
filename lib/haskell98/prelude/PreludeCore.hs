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
    Text(readsPrec, showsPrec, readList, showList), ReadS(..), ShowS(..),
    Binary(readBin, showBin),
--  List type: [_]((:), [])
--  Tuple types: (_,_), (_,_,_), etc.
--  Trivial type: () 
    Bool(True, False),
    Ordering(LT, EQ, GT), Maybe(Nothing, Just), Either(Left, Right),
    Char, Int, Integer, Float, Double, Bin,
    Ratio, Complex((:+)), Assoc((:=)), Array,
    String(..), Rational(..) )  where

{-#Prelude#-}  -- Indicates definitions of compiler prelude symbols

import PreludePrims
import PreludeText
import PreludeNumeric(readSigned, showSigned, readDec, showInt,
		      readFloat, showFloat)
import PreludeChar(ord, chr, minChar, maxChar)
import PreludeRatio(Ratio, Rational(..), (%))
import PreludeComplex(Complex((:+)))
import PreludeArray(Assoc((:=)), Array, listArray, bounds, elems)
import PreludeIO({-Request, Response,-} IOError,
		 Dialogue(..), SuccCont(..), StrCont(..), 
		 StrListCont(..), BinCont(..), FailCont(..))

infixr 8  **
infixl 7  *, /, `quot`, `rem`, `div`, `mod`
infixl 6  +, -
infix  4  ==, /=, <, <=, >=, >


infixr 5 :

data Int = MkInt
data Integer = MkInteger
data Float = MkFloat
data Double   = MkDouble
data Char = MkChar
data Bin = MkBin
-- The constructor order is fixed by the code generator (cons = 0), so a
-- derived Ord would put [] after every non-empty list; Ord is written
-- out below instead.
data List a = a : (List a) | Nil deriving (Eq)
data Arrow a b = MkArrow a b
data UnitType = UnitConstructor deriving (Eq, Ord, Ix, Binary)

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

class  (Eq a, Text a) => Num a  where
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

class  (Ord a, Text a) => Ix a  where   -- This is a Yale modification
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

-- Text class

type  ReadS a = String -> [(a,String)]
type  ShowS   = String -> String

class  Text a  where
    readsPrec :: Int -> ReadS a
    showsPrec :: Int -> a -> ShowS
    readList  :: ReadS [a]
    showList  :: [a] -> ShowS

    readList    = readParen False (\r -> [pr | ("[",s)	<- lex r,
					       pr	<- readl s])
	          where readl  s = [([],t)   | ("]",t)  <- lex s] ++
				   [(x:xs,u) | (x,t)    <- reads s,
					       (xs,u)   <- readl' t]
			readl' s = [([],t)   | ("]",t)  <- lex s] ++
			           [(x:xs,v) | (",",t)  <- lex s,
					       (x,u)	<- reads t,
					       (xs,v)   <- readl' u]
    showList []	= showString "[]"
    showList (x:xs)
		= showChar '[' . shows x . showl xs
		  where showl []     = showChar ']'
			showl (x:xs) = showChar ',' . shows x . showl xs



-- Binary class

class  Binary a  where
    readBin		:: Bin -> (a,Bin)
    showBin		:: a -> Bin -> Bin


-- Maybe and Either (H98).  The Text instances are written out to get
-- the H98 output format.

data  Maybe a  =  Nothing | Just a	deriving (Eq, Ord)

instance  (Text a) => Text (Maybe a)  where
    readsPrec d r =  readParen False
			(\r -> [(Nothing,s) | ("Nothing",s) <- lex r]) r
		  ++ readParen (d > 10)
			(\r -> [(Just x,t) | ("Just",s) <- lex r,
					     (x,t)	<- readsPrec 11 s]) r
    showsPrec d Nothing  = showString "Nothing"
    showsPrec d (Just x) = showParen (d > 10)
			     (showString "Just " . showsPrec 11 x)

data  Either a b  =  Left a | Right b	deriving (Eq, Ord)

instance  (Text a, Text b) => Text (Either a b)  where
    readsPrec d r =  readParen (d > 10)
			(\r -> [(Left x,t) | ("Left",s) <- lex r,
					     (x,t)	<- readsPrec 11 s]) r
		  ++ readParen (d > 10)
			(\r -> [(Right x,t) | ("Right",s) <- lex r,
					      (x,t)	 <- readsPrec 11 s]) r
    showsPrec d (Left x)  = showParen (d > 10)
			      (showString "Left " . showsPrec 11 x)
    showsPrec d (Right x) = showParen (d > 10)
			      (showString "Right " . showsPrec 11 x)

-- Trivial type

-- data  ()  =  ()  deriving (Eq, Ord, Ix, Enum, Binary)

instance  Text ()  where
    readsPrec p    = readParen False
    	    	    	    (\r -> [((),t) | ("(",s) <- lex r,
					     (")",t) <- lex s ] )
    showsPrec p () = showString "()"

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


-- Binary type

instance  Text Bin  where
    readsPrec p s  =  error "readsPrec{PreludeText}: Cannot read Bin."
    showsPrec p b  =  showString "<<Bin>>"


-- Boolean type

data  Bool  =  False | True	deriving (Eq, Ord, Ix, Text, Binary)

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

instance  Text Ordering  where
    readsPrec p r	=  [(LT,s) | ("LT",s) <- lex r] ++
			   [(EQ,s) | ("EQ",s) <- lex r] ++
			   [(GT,s) | ("GT",s) <- lex r]
    showsPrec p LT	=  showString "LT"
    showsPrec p EQ	=  showString "EQ"
    showsPrec p GT	=  showString "GT"


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

instance  Text Char  where
    readsPrec p      = readParen False
    	    	    	    (\r -> [(c,t) | ('\'':s,t)<- lex r,
					    (c,_)     <- readLitChar s])

    showsPrec p '\'' = showString "'\\''"
    showsPrec p c    = showChar '\'' . showLitChar c . showChar '\''

    readList = readParen False (\r -> [(l,t) | ('"':s, t) <- lex r,
					       (l,_)      <- readl s ])
	       where readl ('"':s)	= [("",s)]
		     readl ('\\':'&':s)	= readl s
		     readl s		= [(c:cs,u) | (c ,t) <- readLitChar s,
						      (cs,u) <- readl t	      ]

    showList cs = showChar '"' . showl cs
		 where showl ""       = showChar '"'
		       showl ('"':cs) = showString "\\\"" . showl cs
		       showl (c:cs)   = showLitChar c . showl cs

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
    quotRem		=  primQuotRemInt
    toInteger		=  primIntToInteger

instance  Integral Integer  where
    quotRem		=  primQuotRemInteger
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


instance  Text Int  where
    readsPrec p		= readSigned readDec
    showsPrec p n
	| n == minInt	= showsPrec p (primIntToInteger n)  -- -minInt overflows
	| otherwise	= showSigned showInt p n

minInt, maxInt	:: Int
minInt		=  primMinInt
maxInt		=  primMaxInt

instance  Text Integer  where
    readsPrec p 	= readSigned readDec
    showsPrec		= showSigned showInt


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

instance  Text Float  where
    readsPrec p		= readSigned readFloat
    showsPrec		= showSignedFloat

instance  Text Double  where
    readsPrec p		= readSigned readFloat
    showsPrec		= showSignedFloat


showSignedFloat		:: (RealFloat a) => Int -> a -> ShowS
showSignedFloat p x
	| x < 0 || isNegativeZero x
			= showParen (p > 6) (showChar '-' . showFloat (-x))
	| otherwise	= showFloat x

-- Lists

-- data  [a]  =  [] | a : [a]  deriving (Eq, Ord, Binary)

instance  (Ord a) => Ord [a]  where
    []     <= _	=  True
    (_:_)  <= []	=  False
    (x:xs) <= (y:ys)	=  x < y || (x == y && xs <= ys)
    []     <  []	=  False
    []     <  (_:_)	=  True
    (_:_)  <  []	=  False
    (x:xs) <  (y:ys)	=  x < y || (x == y && xs < ys)

instance  (Text a) => Text [a]  where
    readsPrec p		= readList
    showsPrec p		= showList


-- Tuples

-- data  (a,b)  =  (a,b)  deriving (Eq, Ord, Ix, Binary)
{-
instance  (Text a, Text b) => Text (a,b)  where
    readsPrec p = readParen False
    	    	    	    (\r -> [((x,y), w) | ("(",s) <- lex r,
						 (x,t)   <- reads s,
						 (",",u) <- lex t,
						 (y,v)   <- reads u,
						 (")",w) <- lex v ] )

    showsPrec p (x,y) = showChar '(' . shows x . showChar ',' .
    	    	    	    	       shows y . showChar ')'
-- et cetera
-}

-- Functions

instance  Text (a -> b)  where
    readsPrec p s  =  error "readsPrec{PreludeCore}: Cannot read functions."
    showsPrec p f  =  showString "<<function>>"

-- Support for class Bin

instance Binary Int where
  showBin i b = primShowBinInt i b
  readBin b = primReadBinInt b

instance Binary Integer where
  showBin i b = primShowBinInteger i b
  readBin b = primReadBinInteger b

instance Binary Float where
  showBin f b = primShowBinFloat f b
  readBin b = primReadBinFloat b

instance Binary Double where
  showBin d b = primShowBinDouble d b
  readBin b = primReadBinDouble b

instance Binary Char where
  showBin c b = primShowBinInt (ord c) b
  readBin b = (chr i,b') where
     (i,b') = primReadBinSmallInt b primMaxChar 

instance (Binary a) => Binary [a]  where
    showBin l b = showBin (length l :: Int) (sb1 l b) where
      sb1 [] b = b
      sb1 (h:t) b = showBin h (sb1 t b)
    readBin bin = rbl len bin' where
       len :: Int
       (len,bin') = readBin bin
       rbl 0 b = ([],b)
       rbl n b = (h:t,b'') where
         (h,b') = readBin b
         (t,b'') = rbl (n-1) b'

instance  (Ix a, Binary a, Binary b) => Binary (Array a b)  where
    showBin a = showBin (bounds a) . showBin (elems a)
    readBin bin = (listArray b vs, bin'')
		 where (b,bin')   = readBin bin
		       (vs,bin'') = readBin bin'

{-
instance (Binary a, Binary b) => Binary (a,b) where
  showBin (x,y) = (showBin x) . (showBin y)
  readBin b = ((x,y),b'') where
                (x,b') = readBin b
                (y,b'') = readBin b'

instance (Binary a, Binary b, Binary c) => Binary (a,b,c) where
  showBin (x,y,z) = (showBin x) . (showBin y) . (showBin z)
  readBin b = ((x,y,z),b3) where
                (x,b1) = readBin b
                (y,b2) = readBin b1
	        (z,b3) = readBin b2

instance (Binary a, Binary b, Binary c, Binary d) => Binary (a,b,c,d) where
  showBin (a,b,c,d) = (showBin a) . (showBin b) . (showBin c) . (showBin d)
  readBin b = ((a1,a2,a3,a4),b4) where
                (a1,b1) = readBin b
                (a2,b2) = readBin b1
	        (a3,b3) = readBin b2
	        (a4,b4) = readBin b3
-}
--   Instances for tuples

-- This whole section should be handled in the support code.  For now,
-- only tuple instances expliticly provided here are available.
-- Currently provided:

-- 2,3 tuples: all classes (Eq, Ord, Ix, Bin, Text)
-- 4 tuples: Eq, Bin, Text
-- 5, 6 tuples: Text (printing only)

{- 
rangeSize               :: (Ix a) => (a,a) -> Int
rangeSize (l,u)         =  index (l,u) u + 1

instance (Eq a1, Eq a2) => Eq (a1,a2) where
  (a1,a2) == (z1,z2) = a1==z1 && a2==z2

instance (Ord a1, Ord a2) => Ord (a1,a2) where
  (a1,a2) <= (z1,z2) = a1<=z1 || a1==z1 && a2<=z2 
  (a1,a2) <  (z1,z2) = a1<z1  || a1==z1 && a2<z2

instance (Ix a1, Ix a2) => Ix (a1,a2) where
  range ((l1,l2),(u1,u2)) = [(i1,i2) | i1 <- range(l1,u1),
                                       i2 <- range(l2,u2)]
  index ((l1,l2),(u1,u2)) (i1,i2) = 
    index (l1,u1) i1 * rangeSize (l2,u2)
    + index (l2,u2) i2
  inRange ((l1,l2),(u1,u2)) (i1,i2) =
    inRange (l1,u1) i1 && inRange (l2,u2) i2

{-    Apprears in Joe's code.
instance (Text a1, Text a2) => Text (a1,a2) where
  readsPrec p = readParen False
                          (\r0 -> [((a1,a2), w) | ("(",r1) <- lex r0,
                                                  (a1,r2)  <- reads r1,
                                                  (",",r3) <- lex r2,
                                                  (a2,r4)  <- reads r3,
                                                  (")",w)  <- lex r4 ])

  showsPrec p (a1,a2) = showChar '(' . shows a1 . showChar ',' .
                                       shows a2 . showChar ')'
-}

instance (Eq a1, Eq a2, Eq a3) => Eq (a1,a2,a3) where
  (a1,a2,a3) == (z1,z2,z3) = a1==z1 && a2==z2 && a3==z3

instance (Ord a1, Ord a2, Ord a3) => Ord (a1,a2,a3) where
  (a1,a2,a3) <= (z1,z2,z3) = a1<=z1 || a1==z1 && 
			      (a2<=z2 || a2==z2 &&
				a3<=z3)
  (a1,a2,a3) <  (z1,z2,z3) = a1<z1  || a1==z1 &&
   			      (a2<z2 || a2==z2 &&
           			a3<z3)


instance (Ix a1, Ix a2, Ix a3) => Ix (a1,a2,a3) where
  range ((l1,l2,l3),(u1,u2,u3)) = 
     [(i1,i2,i3) | i1 <- range(l1,u1),
                   i2 <- range(l2,u2),
                   i3 <- range(l3,u3)]
  index ((l1,l2,l3),(u1,u2,u3)) (i1,i2,i3) = 
    (index (l1,u1) i1 * rangeSize (l2,u2)
     + index (l2,u2) i2 ) * rangeSize (l3,u3)
     + index (l3,u3) i3
  inRange ((l1,l2,l3),(u1,u2,u3)) (i1,i2,i3) =
    inRange (l1,u1) i1 && inRange (l2,u2) i2 && inRange (l3,u3) i3


instance (Text a1, Text a2, Text a3) => Text (a1,a2,a3) where
  readsPrec p = readParen False
                          (\r0 -> [((a1,a2,a3), w) |
                                                  ("(",r1) <- lex r0,
                                                  (a1,r2)  <- reads r1,
                                                  (",",r3) <- lex r2,
                                                  (a2,r4)  <- reads r3,
                                                  (",",r5) <- lex r4,
                                                  (a3,r6)  <- reads r5,
                                                  (")",w)  <- lex r6 ])
  showsPrec p (a1,a2,a3) = 
                        showChar '(' . shows a1 . showChar ',' .
                                       shows a2 . showChar ',' .
                                       shows a3 . showChar ')'

instance (Eq a1, Eq a2, Eq a3, Eq a4) => Eq (a1,a2,a3,a4) where
  (a1,a2,a3,a4) == (z1,z2,z3,z4) = a1==z1 && a2==z2 && a3==z3 && a4 == z4

instance (Text a1, Text a2, Text a3, Text a4) => Text (a1,a2,a3,a4) where
  readsPrec p = readParen False
                          (\r0 -> [((a1,a2,a3,a4), w) |
                                                  ("(",r1) <- lex r0,
                                                  (a1,r2)  <- reads r1,
                                                  (",",r3) <- lex r2,
                                                  (a2,r4)  <- reads r3,
                                                  (",",r5) <- lex r4,
                                                  (a3,r6)  <- reads r5,
	                                          (",",r7) <- lex r6,
						  (a4,r8)  <- reads r7,
                                                  (")",w)  <- lex r8 ])
  showsPrec p (a1,a2,a3,a4) = 
                        showChar '(' . shows a1 . showChar ',' .
                                       shows a2 . showChar ',' .
                                       shows a3 . showChar ',' .
                                       shows a4 . showChar ')'

instance (Text a1, Text a2, Text a3, Text a4, Text a5) =>
      Text (a1,a2,a3,a4,a5) where
  readsPrec p = error "Read of 5 tuples not implemented"
  showsPrec p (a1,a2,a3,a4,a5) = 
                        showChar '(' . shows a1 . showChar ',' .
                                       shows a2 . showChar ',' .
                                       shows a3 . showChar ',' .
                                       shows a4 . showChar ',' .
                                       shows a5 . showChar ')'

instance (Text a1, Text a2, Text a3, Text a4, Text a5, Text a6) =>
      Text (a1,a2,a3,a4,a5,a6) where
  readsPrec p = error "Read of 6 tuples not implemented"
  showsPrec p (a1,a2,a3,a4,a5,a6) = 
                        showChar '(' . shows a1 . showChar ',' .
                                       shows a2 . showChar ',' .
                                       shows a3 . showChar ',' .
                                       shows a4 . showChar ',' .
                                       shows a5 . showChar ',' .
                                       shows a6 . showChar ')'


-}
