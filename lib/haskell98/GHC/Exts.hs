{-# LANGUAGE MagicHash #-}
-- GHC.Exts (base) for MagicHash programs.  Yale Haskell has no unboxed
-- types: Int# is Int, Double# is Double, and so on; the boxing
-- constructors I#, D#, ... are the identity (parser/exp-parser.mumble),
-- and the primops are the ordinary operations.  A comparison primop
-- returns 1 or 0, as GHC's do, for isTrue#.
module GHC.Exts (
    Int#, Word#, Double#, Float#, Char#, Addr#,
    (+#), (-#), (*#), quotInt#, remInt#, negateInt#, (==#), (/=#), (<#),
    (<=#), (>#), (>=#), isTrue#, andI#, orI#, xorI#, notI#,
    uncheckedIShiftL#, uncheckedIShiftRA#, uncheckedIShiftRL#,
    (+##), (-##), (*##), (/##), (**##), (==##), (/=##), (<##), (<=##),
    (>##), (>=##), negateDouble#, sqrtDouble#, expDouble#, logDouble#,
    sinDouble#, cosDouble#, int2Double#, double2Int#,
    plusWord#, minusWord#, timesWord#, and#, or#, xor#, not#, shiftL#,
    shiftRL#, int2Word#, word2Int#, eqWord#, ltWord#,
    chr#, ord#, eqChar#, neChar#,
    lazy, inline, oneShot, seq#, build, augment,
    IsList(fromList, toList, fromListN), IsString(fromString)
  ) where

import GHC.IsList (IsList(fromList, toList, fromListN))

import Data.Bits
import Data.Word (Word)
import Data.String (IsString(fromString))

infixl 7 *#, `quotInt#`, `remInt#`, *##, /##
infixl 6 +#, -#, +##, -##
infix 4 ==#, /=#, <#, <=#, >#, >=#, ==##, /=##, <##, <=##, >##, >=##

type Int# = Int
type Word# = Word
type Double# = Double
type Float# = Float
type Char# = Char
type Addr# = Int

b2i :: Bool -> Int
b2i b = if b then 1 else 0

(+#), (-#), (*#), quotInt#, remInt#, andI#, orI#, xorI# :: Int -> Int -> Int
(+#) = (+)
(-#) = (-)
(*#) = (*)
quotInt# = quot
remInt# = rem
andI# = (.&.)
orI# = (.|.)
xorI# = xor

negateInt#, notI# :: Int -> Int
negateInt# = negate
notI# = complement

(==#), (/=#), (<#), (<=#), (>#), (>=#) :: Int -> Int -> Int
a ==# b = b2i (a == b)
a /=# b = b2i (a /= b)
a <# b = b2i (a < b)
a <=# b = b2i (a <= b)
a ># b = b2i (a > b)
a >=# b = b2i (a >= b)

isTrue# :: Int -> Bool
isTrue# n = n /= 0

uncheckedIShiftL#, uncheckedIShiftRA#, uncheckedIShiftRL# :: Int -> Int -> Int
uncheckedIShiftL# = shiftL
uncheckedIShiftRA# = shiftR
uncheckedIShiftRL# a n = if a >= 0 then shiftR a n else shiftR a n

(+##), (-##), (*##), (/##), (**##) :: Double -> Double -> Double
(+##) = (+)
(-##) = (-)
(*##) = (*)
(/##) = (/)
(**##) = (**)

(==##), (/=##), (<##), (<=##), (>##), (>=##) :: Double -> Double -> Int
a ==## b = b2i (a == b)
a /=## b = b2i (a /= b)
a <## b = b2i (a < b)
a <=## b = b2i (a <= b)
a >## b = b2i (a > b)
a >=## b = b2i (a >= b)

negateDouble#, sqrtDouble#, expDouble#, logDouble#, sinDouble#,
  cosDouble# :: Double -> Double
negateDouble# = negate
sqrtDouble# = sqrt
expDouble# = exp
logDouble# = log
sinDouble# = sin
cosDouble# = cos

int2Double# :: Int -> Double
int2Double# = fromIntegral

double2Int# :: Double -> Int
double2Int# = truncate

plusWord#, minusWord#, timesWord#, and#, or#, xor# :: Word -> Word -> Word
plusWord# = (+)
minusWord# = (-)
timesWord# = (*)
and# = (.&.)
or# = (.|.)
xor# = xor

not# :: Word -> Word
not# = complement

shiftL#, shiftRL# :: Word -> Int -> Word
shiftL# = shiftL
shiftRL# = shiftR

int2Word# :: Int -> Word
int2Word# = fromIntegral

word2Int# :: Word -> Int
word2Int# = fromIntegral

eqWord#, ltWord# :: Word -> Word -> Int
eqWord# a b = b2i (a == b)
ltWord# a b = b2i (a < b)

chr# :: Int -> Char
chr# = toEnum

ord# :: Char -> Int
ord# = fromEnum

eqChar#, neChar# :: Char -> Char -> Int
eqChar# a b = b2i (a == b)
neChar# a b = b2i (a /= b)

lazy, inline, oneShot :: a -> a
lazy x = x
inline x = x
oneShot x = x

seq# :: a -> s -> (s, a)
seq# a s = a `seq` (s, a)

build :: ((a -> [a] -> [a]) -> [a] -> [a]) -> [a]
build g = g (:) []

augment :: ((a -> [a] -> [a]) -> [a] -> [a]) -> [a] -> [a]
augment g xs = g (:) xs
